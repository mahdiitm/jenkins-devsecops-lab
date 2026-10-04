FROM python:3.12-alpine3.24

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

RUN adduser -D appuser

USER appuser

EXPOSE 8080

CMD ["python", "app.py"]
