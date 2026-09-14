FROM python:3.12-slim

WORKDIR /app

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

ENV DB_HOST="" \
    DB_NAME="" \
    DB_USER="" \
    DB_PASSWORD=""

EXPOSE 8080

CMD ["python", "app.py"]
