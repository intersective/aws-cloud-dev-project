FROM --platform=linux/amd64 public.ecr.aws/nginx/nginx:mainline

ADD index.html /etc/nginx/html/index.html
ADD nginx.conf /etc/nginx/nginx.conf
ADD .htpasswd /etc/nginx/.htpasswd