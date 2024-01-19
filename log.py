import logging


class LogFormatter(logging.Formatter):
    yellow = "\x1b[33;20m"
    red = "\x1b[31;20m"
    green = "\x1b[32;20m"
    cyan = "\x1b[36;20m"
    reset = "\x1b[0m"
    front = "[+] "
    format = "%(message)s"

    FORMATS = {
        logging.DEBUG: green + front + "DBUG: " + reset + format,
        logging.INFO: cyan + front + "INFO: " + reset + format,
        logging.WARNING: yellow + front + "WARN: " + reset + format,
        logging.ERROR: red + front + "ERRO: " + reset + format,
        logging.CRITICAL: red + front + "CRIT: " + reset + format,
    }

    def format(self, record):
        log_format = self.FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_format)
        return formatter.format(record)


log = logging.getLogger("tools")
log.setLevel(logging.INFO)

log_handler = logging.StreamHandler()
# log_handler.setLevel(logging.INFO)
log_handler.setFormatter(LogFormatter())
log.addHandler(log_handler)
