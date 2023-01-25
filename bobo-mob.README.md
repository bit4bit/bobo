# bobo-mob

~~~
$ docker run --rm -ti -p 8000:80 -v <MI PROJECT DIRECTORY>:/app -v $(pwd)/server.pem:/etc/bobo-mob.crt -v $(pwd)/server.key:/etc/bobo-mob.key bit4bit/bobo-mob:latest
~~~
