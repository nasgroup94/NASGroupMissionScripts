import logging
# from logging import config


def logger(module: str, filename: str, mode: str, debug: bool) -> logging.Logger:
    logger = logging.getLogger(module)

    handler_stream = logging.StreamHandler()
    handler_file = logging.FileHandler(filename, mode)

    formatter = logging.Formatter(
            '[%(asctime)s] [%(levelname)-6s] [%(module)s:%(funcName)s():%(lineno)s] %(message)s',
            '%y-%m-%d %H:%M:%S')
    handler_stream.setFormatter(formatter)
    handler_file.setFormatter(formatter)

    logger.addHandler(handler_stream)
    logger.addHandler(handler_file)

    if debug == True:
        logger.setLevel(logging.DEBUG)
    else:
        logger.setLevel(logging.INFO)

    return logger
