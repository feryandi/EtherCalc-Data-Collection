FROM node:4.4

RUN useradd ethercalc --create-home
#RUN npm install -g ethercalc pm2
RUN npm install -g pm2

COPY . /home/ethercalc/ethercalc
RUN npm i /home/ethercalc/ethercalc

USER ethercalc
ENV HOME /home/ethercalc
EXPOSE 8000

#RUN cd /home/ethercalc/ethercalc && make

#CMD ["sh", "-c", "REDIS_HOST=$REDIS_PORT_6379_TCP_ADDR REDIS_PORT=$REDIS_PORT_6379_TCP_PORT pm2 start -x `which ethercalc` -- --cors && pm2 logs"]

CMD ["sh", "-c", "REDIS_HOST=$REDIS_PORT_6379_TCP_ADDR REDIS_PORT=$REDIS_PORT_6379_TCP_PORT MYSQL_HOST=$MYSQL_PORT_3306_TCP_ADDR MYSQL_PORT=$MYSQL_PORT_3306_TCP_PORT pm2 start -x /home/ethercalc/ethercalc/app.js -- --cors && pm2 logs"]
