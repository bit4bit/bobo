# bobo-mob

~~~
$ docker run --rm -ti -p 8000:80 -v <MI PROJECT DIRECTORY>:/app -v $(pwd)/client.pem:/etc/bobo-programmer.crt bit4bit/bobo-programmer:latest -- -i mymob -u progammer -l <HOST BOBO-MOB> -d /app
~~~

open browser `http://localhost:8000`
