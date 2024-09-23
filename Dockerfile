## Base image as builder
FROM python:3.11-slim-buster AS builder

# Set the working directory inside the container
WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    wget build-essential libsqlite3-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
    
# Download and install SQLite 3.41 or later
RUN wget https://www.sqlite.org/2023/sqlite-autoconf-3410000.tar.gz \
    && tar -xzf sqlite-autoconf-3410000.tar.gz \
    && cd sqlite-autoconf-3410000 \
    && ./configure \
    && make \
    && make install \
    && cd .. \
    && rm -rf sqlite-autoconf-3410000* 

# Refresh shared library cache to ensure new SQLite version is used
RUN ldconfig

# Set environment variable to use the installed SQLite version
ENV LD_LIBRARY_PATH=/usr/local/lib

# Install Python requirements
ENV PYTHONUNBUFFERED=1

# Copy requirements to the container
COPY requirements.txt /app
#install requirements,don't cache files
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code directory to the app directory
COPY source /app

# retrieve static files
RUN python manage.py collectstatic --noinput

# Base image for final stage
FROM python:3.11-slim-buster

# Set working directory
WORKDIR /app

# Copy the build from the previous stage
COPY --from=builder / /

# Expose port 8000 for the Django app
EXPOSE 8000

# Default command to run Django's development server
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
