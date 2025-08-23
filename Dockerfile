FROM python:3.11

# Install required Python packages
RUN pip install pandas sqlalchemy psycopg2-binary pyarrow

WORKDIR /app

COPY . /app/
RUN chmod +x main.py
RUN pip install -r requirements.txt


ENTRYPOINT [ "python","main.py" ]
