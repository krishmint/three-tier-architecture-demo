FROM python:3.9

EXPOSE 8080
USER root

ENV INSTANA_SERVICE_NAME=payment

WORKDIR /app

COPY . /app/

RUN pip install -r requirements.txt

#CMD ["python", "payment.py"]
CMD ["uwsgi", "--ini", "payment.ini"]  
## uwsgi-> web server gateway interface (WSGI) implementation. The --ini option tells uwsgi to use the configuration file payment.ini
##payment.ini. is a configuration file which contains settings for the uwsgi server and the application to serve
