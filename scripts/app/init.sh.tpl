#!/bin/bash

echo "export DB_HOST='mongodb://${db_priv_ip}:27017/posts'" >> /home/ubuntu/.bashrc
export DB_HOST='mongodb://${db_priv_ip}:27017/posts'
cd /home/ubuntu/app
sudo chown -R 1000:1000 "/home/ubuntu/.npm"
sudo npm install
node seeds/seed.js
npm start
