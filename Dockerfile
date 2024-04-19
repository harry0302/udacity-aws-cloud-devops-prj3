FROM python:3.10-slim-buster

WORKDIR /app

COPY /analytics /app

RUN pip install --no-cache-dir -r requirements.txt

ENTRYPOINT ["python", "app.py"]