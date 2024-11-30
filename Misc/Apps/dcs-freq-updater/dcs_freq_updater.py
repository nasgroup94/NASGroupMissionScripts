import shutil
from datetime import datetime
from pathlib import Path
from typing import OrderedDict
from zipfile import ZipFile

import luadata
from config.logger import logger

set_debug = True
log = logger(__name__, "dcs_freq_updater.log", "w", debug=set_debug)


current_timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
folder_source: Path = Path("_source")
folder_build: Path = Path("_build")
folder_release: Path = Path("_release", current_timestamp)

master_list: list = []
mission_files: list = []

UpdatedFreqs: OrderedDict = OrderedDict(
    {
        0: 305,
        1: 260,
        2: 265,
        3: 256,
        4: 254,
        5: 250,
        6: 270,
        7: 271.525,
        8: 250.1,
        9: 262,
        10: 369.5,
        11: 268,
        12: 269,
        13: 261,
        14: 236.275,
        15: 264,
        16: 267,
        17: 251,
        18: 253,
        19: 266,
    }
)


# Create a list of miz file contained in the source folder
for master_file in folder_source.glob("*.miz"):
    current_master: dict = {}
    current_master["file"] = master_file.name
    current_master["name"] = master_file.stem
    master_list.append(current_master)

mission_files.append(master_list)

# Unzip miz to the build folder
for master_mission in mission_files[0]:
    master_build_folder = Path(folder_build, master_mission["name"])
    master_file = Path(folder_source, master_mission["file"])
    master_zip = ZipFile(master_file, "r")
    master_zip.extractall(master_build_folder)
    log.debug(f"Unzipped {master_file} to {master_build_folder}.")

    # Read mission file into python dict
    mission_master_temp = Path(master_build_folder, "mission")
    log.debug(f"Reading data from {master_file.name}.")
    master_data = luadata.read(mission_master_temp, encoding="utf-8", multival=False)
    log.debug(f"Read data from {master_file.name}.")

    for group_idx, group in enumerate(
        master_data["coalition"]["blue"]["country"][0]["plane"]["group"]
    ):
        for unit_idx, unit in enumerate(group["units"]):
            if (
                unit["type"] == "FA-18C_hornet"
                or unit["type"] == "F-14B"
                or unit["type"] == "F-14A-135-GR"
                or unit["type"] == "AV8BNA"
            ) and unit.get("Radio") is not None:
                for radio_idx, radio in enumerate(unit["Radio"]):
                    print(radio_idx, radio)
                    for chn_idx, chn_freq in enumerate(radio["channels"]):
                        # print(chn_idx, chn)
                        if chn_idx <= 19:
                            for upd_idx, upd_freq in UpdatedFreqs.items():
                                # print(chn_idx, upd_idx, ' : ', chn_freq, upd_freq)
                                if chn_idx == upd_idx:
                                    # print('channels match')
                                    chn_freq = upd_freq
                                    master_data["coalition"]["blue"]["country"][0][
                                        "plane"
                                    ]["group"][group_idx]["units"][unit_idx]["Radio"][
                                        radio_idx
                                    ][
                                        "channels"
                                    ][
                                        chn_idx
                                    ] = upd_freq
                                    # break

    # Write a new mission file with the updated data
    luadata.write(
        mission_master_temp,  # wx_mission_temp,
        master_data,
        encoding="utf-8",
        indent="    ",
        prefix="mission = ",
    )

    new_filename = f"{master_file.stem}_updated.miz"
    release_file = Path(folder_release, new_filename)

    shutil.make_archive(release_file.__str__(), "zip", master_build_folder.__str__())
    shutil.move(f"{release_file.__str__()}.zip", f"{release_file.__str__()}")
