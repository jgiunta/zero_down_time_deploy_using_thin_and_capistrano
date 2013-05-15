
upstream thin {
  ip_hash;
  server 127.0.0.1:3000;
  server 127.0.0.1:3001;
  server 127.0.0.1:3002;
}

server {
  listen 80 default;
  server_name_in_redirect off;
  rewrite ^ http://www.example.com$request_uri;
}

server {
  listen 80;
  server_name www.example.com;

  access_log /var/log/nginx/www.example.com/access.log;
  error_log /var/log/nginx/www.example.com/error.log;
  root /home/www.example.com/current/public;

  try_files $uri/index.html $uri @thin;

  location @thin {
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;
    proxy_max_temp_file_size 0;
    if (-f $request_filename) {
      expires max;
      break;
    }

    if (!-f $request_filename) {
      proxy_pass http://thin;
      break;
    }
  }

  error_page 500 502 503 504 /500.html;
  client_max_body_size 4G;
  keepalive_timeout 10;
  gzip_static on;

  # Replace domain.com with your domain
  if ($host = example.com) {
    rewrite ^/(.*)$ http://www.example.com/$1 permanent;
  }

}

