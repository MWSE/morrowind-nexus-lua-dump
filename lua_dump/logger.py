from __future__ import annotations

from loguru import Logger, Record, logger

__all__ = ["logger", "init_logger"]


def _format(record: Record) -> str:
    source = "{file}:{line}".format(**record)
    record["extra"]["source"] = source[-24:]
    return (
        "<green>{time:YYYY-MM-DD HH:mm:ss.SSS}</green>"
        " | "
        "<level>{level:^8}</level>"
        " | "
        "<cyan>{extra[source]:>24}</cyan>"
        " | "
        "<level>{message}</level>"
        "\n"
    )


def init_logger() -> Logger:
    from sys import stderr
    from datetime import datetime

    now = datetime.now().strftime("%Y-%m-%d %H-%M-%S")
    logger.remove()  # remove the default sync handler
    logger.add(stderr, format=_format, enqueue=True)
    logger.add(f"logs/{now}.log", format=_format, enqueue=True)

    return logger
