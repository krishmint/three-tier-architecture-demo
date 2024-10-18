FROM mongo:5

COPY *.js /docker-entrypoint-initdb.d/
##two JavaScript files, catalogue.js and user.js, are scripts designed to  populate the MongoDB database with data
## (/docker-entrypoint-initdb.d/ ) directory, which is a special directory that MongoDB automatically executes scripts from when the container starts

