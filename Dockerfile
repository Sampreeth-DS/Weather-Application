# Use an official Python runtime as a parent image
FROM python:3.9-alpine

# Set the working directory
WORKDIR /Weather-App

# Copy the application files
COPY Weather-App-Django /Weather-App/

# Install dependencies
RUN pip install -r requirements.txt

# Expose the port the app runs on
EXPOSE 9000

# Run the application
CMD ["python", "manage.py", "runserver", "0.0.0.0:9000"]