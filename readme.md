Set up Laravel, Nginx, and MySQL with Docker
Step 1: Download Laravel
- Clone project (git clone https://github.com/laravel/laravel.git laravel-app)
- Go to laravel-app directory (cd laravel-app)

Step 2: Create Docker compose file
- Create Docker Compose File
````
nano ~/laravel-app/docker-compose.yml
```
- Define three services: app, webserver and db and make sure to replace the 'root' password for MYSQL_ROOT_PASSWORD.
```
version: '3'
services:

  #PHP Service
  app:
    build:
      context: .
      dockerfile: Dockerfile
    image: digitalocean.com/php
    container_name: app
    restart: unless-stopped
    tty: true
    environment:
      SERVICE_NAME: app
      SERVICE_TAGS: dev
    working_dir: /var/www
    networks:
      - app-network

  #Nginx Service
  webserver:
    image: nginx:alpine
    container_name: webserver
    restart: unless-stopped
    tty: true
    ports:
      - "80:80"
      - "443:443"
    networks:
      - app-network

  #MySQL Service
  db:
    image: mysql:5.7.22
    container_name: db
    restart: unless-stopped
    tty: true
    ports:
      - "3306:3306"
    environment:
      MYSQL_DATABASE: laravel
      MYSQL_ROOT_PASSWORD: your_mysql_root_password
      SERVICE_TAGS: dev
      SERVICE_NAME: mysql
    networks:
      - app-network

#Docker Networks
networks:
  app-network:
    driver: bridge

Step 3: Persisting Data
- In the docker-compose file, define volume as 'dbdata' under 'db' 
```
#MySQL Service
db:
  ...
    volumes:
      - dbdata:/var/lib/mysql
    networks:
      - app-network
```

- At the bottom of the file, add the definition for the 'dbdata' volume
```
#Volumes
volumes:
  dbdata:
    driver: local
```

- bind mount to the db service
```
#MySQL Service
db:
  ...
    volumes:
      - dbdata:/var/lib/mysql
 -->  - ./mysql/my.cnf:/etc/mysql/my.cnf
````

- add bind mount to the 'webserver' service
```
Nginx Service
webserver:
  ...
  volumes:
      - ./:/var/www
      - ./nginx/conf.d/:/etc/nginx/conf.d/
  networks:
      - app-network
````

- Finally, add the bind mount to the 'app' service
```
#PHP Service
app:
  ...
  volumes:
       - ./:/var/www
       - ./php/local.ini:/usr/local/etc/php/conf.d/local.ini
  networks:
      - app-network
```

Step 4: Create the Dockerfile
- Dockerfile will be located in 'laravel-app', create the file 
```
nano ~/laravel-app/Dockerfile
```
- Add the following code
```
FROM php:7.2-fpm

# Copy composer.lock and composer.json
COPY composer.lock composer.json /var/www/

# Set working directory
WORKDIR /var/www

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    mysql-client \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    git \
    curl

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install extensions
RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl
RUN docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/
RUN docker-php-ext-install gd

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Add user for laravel application
RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www

# Copy existing application directory contents
COPY . /var/www

# Copy existing application directory permissions
COPY --chown=www:www . /var/www

# Change current user to www
USER www

# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]
```

Step 5: Configuring PHP
- Create 'local.ini' file inside php folder 
```
/usr/local/etc/php/conf.d/local.ini
````

- Create php directory 
````
mkdir ~/laravel-app/php
````
- Open the 'local.ini' file and add the following code
````
upload_max_filesize=40M
post_max_size=40M
````
Step 6: Coniguring Nginx
- Create 'nginx/conf.d/' directory
```
mkdir -p ~/laravel-app/nginx/conf.d
````
- Create the 'app.conf' configuration file
````
nano ~/laravel-app/nginx/conf.d/app.conf
````
- Add the following code
````
server {
    listen 80;
    index index.php index.html;
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root /var/www/public;
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass app:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
    location / {
        try_files $uri $uri/ /index.php?$query_string;
        gzip_static on;
    }
}
````
Step 7: Configuring MySql
- Create the 'mysql' directory
````
mkdir ~/laravel-app/mysql
````
- Create athe 'my.cnf' file
````
nano ~/laravel-app/mysql/my.cnf
````
- Add the following code
````
[mysqld]
general_log = 1
general_log_file = /var/lib/mysql/general.log
````
Step 8: Run the container and modifying environment settings
- Copy the '.env-example to .env'
```
cp .env.example .env
````
- Run 'docker-compose up' to start all the container, creat volume, set up, and connect network
```
docker-compose up -d
```
````
docker ps
````
is the command to list all the running containers
- To check file .env using command
```
docker-compose exec app nano .env
````
- See the following code '/var/www/.env'
````
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laraveluser
DB_PASSWORD=your_laravel_db_password
```
- Generate a key
```
docker-compose exec app php artisan key:generate
````
- Finally step visit 'http://server_ip'
Example ``` localhost:80```

