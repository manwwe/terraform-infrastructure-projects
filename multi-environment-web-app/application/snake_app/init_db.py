import logging
import time
from collections.abc import Callable

from .database import create_repository


LOGGER = logging.getLogger(__name__)


def initialize_with_retry(
    initialize: Callable[[], None],
    attempts: int = 5,
    delay_seconds: int = 5,
    sleep: Callable[[float], None] = time.sleep,
) -> None:
    if attempts < 1:
        raise ValueError("attempts must be at least one")

    for attempt in range(1, attempts + 1):
        try:
            initialize()
            return
        except Exception:
            if attempt == attempts:
                raise
            LOGGER.warning(
                "Database initialization attempt %s of %s failed",
                attempt,
                attempts,
                exc_info=True,
            )
            sleep(delay_seconds)


def main() -> None:
    logging.basicConfig(level=logging.INFO)
    initialize_with_retry(create_repository().initialize)


if __name__ == "__main__":
    main()
