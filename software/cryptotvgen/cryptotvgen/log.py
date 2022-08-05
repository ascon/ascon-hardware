# -*- coding: utf-8 -*-

import logging

def setup_logger(log_filename):
    '''
    Setup logging infrastructure

    Reference Source: https://realpython.com/python-logging/
    '''
    #logging.basicConfig(level=logging.DEBUG)
    
    # Create a custom logger
    logger = logging.getLogger(__name__)
    

    # Create handlers
    # All messages goes to a log file
    i_handler = logging.FileHandler(log_filename)
    i_handler.setLevel(logging.INFO)

    # Create formatters and add it to handlers
    format = '%(asctime)s - %(levelname)s - %(message)s'
    formatter = logging.Formatter(format)
    i_handler.setFormatter(formatter)

    # Add handlers to the logger
    logger.addHandler(i_handler)

    return logger
