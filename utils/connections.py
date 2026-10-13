import os

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

load_dotenv()

app_engine = create_engine(os.getenv('APP_DB_URL'))
dw_engine = create_engine(os.getenv('DW_DB_URL'))

app_session_factory = sessionmaker(bind=app_engine)
dw_session_factory = sessionmaker(bind=dw_engine)
