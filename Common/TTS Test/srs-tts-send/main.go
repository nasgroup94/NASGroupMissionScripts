package main

import (
	"bytes"
	"context"
	"encoding/binary"
	"errors"
	"flag"
	"fmt"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/dharmab/skyeye/pkg/coalitions"
	"github.com/dharmab/skyeye/pkg/simpleradio"
	"github.com/dharmab/skyeye/pkg/simpleradio/types"
)

const expectedSampleRate = 16000

func parseModulation(value string) (types.Modulation, error) {
	switch strings.ToUpper(strings.TrimSpace(value)) {
	case "0", "AM":
		return types.ModulationAM, nil
	case "1", "FM":
		return types.ModulationFM, nil
	default:
		return types.ModulationAM, fmt.Errorf("unsupported modulation %q", value)
	}
}

func parseCoalition(value int) coalitions.Coalition {
	switch value {
	case 1:
		return coalitions.Red
	case 2:
		return coalitions.Blue
	default:
		return coalitions.Neutrals
	}
}

func readF32LEMonoPCM(path string, volume float64) (simpleradio.Audio, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read PCM file: %w", err)
	}

	if len(data) == 0 {
		return nil, errors.New("PCM file is empty")
	}

	if len(data)%4 != 0 {
		return nil, fmt.Errorf("PCM file size must be divisible by 4 bytes, got %d", len(data))
	}

	sampleCount := len(data) / 4
	audio := make([]float32, sampleCount)

	reader := bytes.NewReader(data)
	if err := binary.Read(reader, binary.LittleEndian, &audio); err != nil {
		return nil, fmt.Errorf("decode float32 PCM: %w", err)
	}

	if volume != 1.0 {
		for i := range audio {
			audio[i] = float32(float64(audio[i]) * volume)

			if audio[i] > 1.0 {
				audio[i] = 1.0
			}

			if audio[i] < -1.0 {
				audio[i] = -1.0
			}
		}
	}

	return audio, nil
}

func transmitFile(
	ctx context.Context,
	srsAddress string,
	clientName string,
	coalitionID int,
	frequencyMHz float64,
	modulationName string,
	externalAWACSModePassword string,
	filePath string,
	volume float64,
) error {
	modulation, err := parseModulation(modulationName)
	if err != nil {
		return err
	}

	audio, err := readF32LEMonoPCM(filePath, volume)
	if err != nil {
		return err
	}

	if len(audio) == 0 {
		return errors.New("decoded audio is empty")
	}

	radio := types.Radio{
		Frequency:  frequencyMHz * 1_000_000.0,
		Modulation: modulation,
	}

	client, err := simpleradio.NewClient(types.ClientConfiguration{
		Address:                   srsAddress,
		ConnectionTimeout:         10 * time.Second,
		ClientName:                clientName,
		ExternalAWACSModePassword: externalAWACSModePassword,
		Coalition:                 parseCoalition(coalitionID),
		Radios:                    []types.Radio{radio},
		AllowRecording:            true,
		Mute:                      false,
	})
	if err != nil {
		return fmt.Errorf("create SRS client: %w", err)
	}

	runCtx, cancel := context.WithCancel(ctx)
	defer cancel()

	var wg sync.WaitGroup
	runErrCh := make(chan error, 1)

	go func() {
		runErrCh <- client.Run(runCtx, &wg)
	}()

	// Give the SRS client time to TCP/UDP sync and enter External AWACS mode.
	select {
	case err := <-runErrCh:
		if err != nil {
			return fmt.Errorf("SRS client stopped during startup: %w", err)
		}

		return errors.New("SRS client stopped during startup")
	case <-time.After(2 * time.Second):
	case <-ctx.Done():
		return ctx.Err()
	}

	duration := time.Duration(float64(len(audio))/float64(expectedSampleRate)*float64(time.Second)) + 3*time.Second

	fmt.Printf("transmitting %d samples, estimated duration %s\n", len(audio), duration)

	client.Transmit(simpleradio.Transmission{
		TraceID:    strconv.FormatInt(time.Now().UnixNano(), 10),
		ClientName: clientName,
		Audio:      audio,
	})

	select {
	case err := <-runErrCh:
		if err != nil {
			return fmt.Errorf("SRS client stopped during transmit: %w", err)
		}

		return errors.New("SRS client stopped during transmit")
	case <-time.After(duration):
	case <-ctx.Done():
		return ctx.Err()
	}

	cancel()
	wg.Wait()

	return nil
}

func main() {
	var (
		srsAddress                string
		clientName                string
		coalitionID               int
		frequencyMHz              float64
		modulation                string
		externalAWACSModePassword string
		filePath                  string
		volume                    float64
		timeoutSeconds            int
	)

	flag.StringVar(&srsAddress, "srs-address", "127.0.0.1:5002", "SRS server address, including port.")
	flag.StringVar(&clientName, "client-name", "NASGroup TTS", "SRS client name.")
	flag.IntVar(&coalitionID, "coalition", 2, "SRS coalition: 1 red, 2 blue, other neutral.")
	flag.Float64Var(&frequencyMHz, "frequency", 250.0, "Radio frequency in MHz.")
	flag.StringVar(&modulation, "modulation", "AM", "Radio modulation: AM or FM.")
	flag.StringVar(&externalAWACSModePassword, "external-awacs-password", "", "External AWACS mode password.")
	flag.StringVar(&filePath, "file", "", "Raw float32 little-endian mono 16k PCM file to transmit.")
	flag.Float64Var(&volume, "volume", 1.0, "Playback volume multiplier.")
	flag.IntVar(&timeoutSeconds, "timeout", 120, "Overall timeout in seconds.")
	flag.Parse()

	if filePath == "" {
		fmt.Fprintln(os.Stderr, "--file is required")
		os.Exit(2)
	}

	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(timeoutSeconds)*time.Second)
	defer cancel()

	fmt.Printf("SRS address: %s\n", srsAddress)
	fmt.Printf("Client name: %s\n", clientName)
	fmt.Printf("Coalition: %d\n", coalitionID)
	fmt.Printf("Frequency MHz: %.6f\n", frequencyMHz)
	fmt.Printf("Modulation: %s\n", modulation)
	fmt.Printf("File: %s\n", filePath)

	if externalAWACSModePassword == "" {
		fmt.Println("External AWACS password: empty")
	} else {
		fmt.Println("External AWACS password: set")
	}

	if err := transmitFile(
		ctx,
		srsAddress,
		clientName,
		coalitionID,
		frequencyMHz,
		modulation,
		externalAWACSModePassword,
		filePath,
		volume,
	); err != nil {
		fmt.Fprintf(os.Stderr, "transmit failed: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("transmit complete")
}
