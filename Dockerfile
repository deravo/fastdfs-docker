FROM centos:7
LABEL maintainer="Alvin Jin<tenkuking@163.com>"
ENV FASTDFS_PATH=/opt/fdfs \
    FASTDFS_BASE_PATH=/var/fdfs \
	FASTDFS_TRACKER_PATH=/var/fdfs \
	FASTDFS_STORAGE_PATH=/var/fdfs/storage \
    PORT= \
    GROUP_NAME= \
    TRACKER_SERVER=

ENV NGINX_VERSION 1.13.3
ENV ECHO_NGINX_MODULE_VERSION master
ENV FASTDFS_NGINX_MODULE_VERSION master
ENV NGINX_EVAL_MODULE_VERSION master
ENV NGX_HTTP_REDIS_VERSION 0.3.8
ENV LIBFASTCOMMON_VERSION 1.0.37
ENV FASTDFS_VERSION 5.12
  

#get all the dependences
RUN yum install -y git make gcc gcc-c++ gd gd-devel gnupg libc libc-devel libevent libevent-devel libxslt libxslt-devel linux-headers openssl openssl-devel pcre pcre-devel perl unzip zlib zlib-devel gettext

#create the dirs to store the files downloaded from internet
RUN mkdir -p ${FASTDFS_PATH}/libfastcommon \
	&& mkdir -p ${FASTDFS_PATH}/fastdfs \
	&& mkdir ${FASTDFS_BASE_PATH} \
	&& mkdir ${FASTDFS_BASE_PATH}/storage \
	&& mkdir ${FASTDFS_BASE_PATH}/tracker

#compile the libfastcommon with source code from github
#WORKDIR ${FASTDFS_PATH}/libfastcommon
#RUN git clone --branch V1.0.37 --depth 1 https://github.com/happyfish100/libfastcommon.git ${FASTDFS_PATH}/libfastcommon \
#RUN git clone https://github.com/happyfish100/libfastcommon.git ${FASTDFS_PATH}/libfastcommon \
#	&& ./make.sh \
#	&& ./make.sh install \
#	&& rm -rf ${FASTDFS_PATH}/libfastcommon

#compile the fastdfs with source code from github
#WORKDIR ${FASTDFS_PATH}/fastdfs
#RUN git clone --branch V5.12 --depth 1 https://github.com/happyfish100/fastdfs.git ${FASTDFS_PATH}/fastdfs \
#RUN git clone https://github.com/happyfish100/fastdfs.git ${FASTDFS_PATH}/fastdfs \
#	&& ./make.sh \
#	&& ./make.sh install \
#	&& rm -rf ${FASTDFS_PATH}/fastdfs

#compile the libfastcommon with source code zip file
WORKDIR ${FASTDFS_PATH}/libfastcommon
ADD files/libfastcommon-${LIBFASTCOMMON_VERSION}.zip ${FASTDFS_PATH}/libfastcommon
RUN unzip libfastcommon-${LIBFASTCOMMON_VERSION}.zip \
	&& cd libfastcommon-${LIBFASTCOMMON_VERSION} \
	&& ./make.sh \
	&& ./make.sh install \
	&& rm -rf ${FASTDFS_PATH}/libfastcommon

#compile the fastdfs with source code zip file
WORKDIR ${FASTDFS_PATH}/fastdfs
ADD files/fastdfs-${FASTDFS_VERSION}.zip ${FASTDFS_PATH}/fastdfs
RUN unzip fastdfs-${FASTDFS_VERSION}.zip \
	&& cd fastdfs-${FASTDFS_VERSION} \
	&& ./make.sh \
	&& ./make.sh install \
	&& rm -rf ${FASTDFS_PATH}/fastdfs

## unzip nginx modules
ADD files/nginx/modules/echo-nginx-module-$ECHO_NGINX_MODULE_VERSION.zip /usr/src/
ADD files/nginx/modules/fastdfs-nginx-module-$FASTDFS_NGINX_MODULE_VERSION.zip /usr/src/
ADD files/nginx/modules/nginx-eval-module-$NGINX_EVAL_MODULE_VERSION.zip /usr/src/
## command ADD will auto unzip tar.gz
ADD files/nginx/modules/ngx_http_redis-$NGX_HTTP_REDIS_VERSION.tar.gz /usr/src/
RUN cd /usr/src \
	&& unzip echo-nginx-module-$ECHO_NGINX_MODULE_VERSION.zip \
	&& unzip fastdfs-nginx-module-$FASTDFS_NGINX_MODULE_VERSION.zip \
	&& unzip nginx-eval-module-$NGINX_EVAL_MODULE_VERSION.zip

## install nginx with extra modules
## refer to： https://github.com/nginxinc/docker-nginx/blob/1.13.2/mainline/alpine/Dockerfile
ADD files/nginx/nginx-$NGINX_VERSION.tar.gz /usr/src/
RUN mkdir -p /var/cache/nginx/client_temp \
	&& mkdir /var/cache/nginx/proxy_temp \
	&& mkdir /var/cache/nginx/fastcgi_temp \
	&& mkdir /var/cache/nginx/uwsgi_temp \
	&& mkdir /var/cache/nginx/scgi_temp
RUN CONFIG="\
		--prefix=/usr/local/nginx \
		--sbin-path=/usr/sbin/nginx \
		--modules-path=/usr/lib/nginx/modules \
		--conf-path=/usr/local/nginx/nginx.conf \
		--error-log-path=/var/log/nginx/error.log \
		--http-log-path=/var/log/nginx/access.log \
		--pid-path=/var/run/nginx.pid \
		--lock-path=/var/run/nginx.lock \
		--http-client-body-temp-path=/var/cache/nginx/client_temp \
		--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
		--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
		--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
		--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
		--with-http_ssl_module \
		--with-http_realip_module \
		--with-http_addition_module \
		--with-http_sub_module \
		--with-http_dav_module \
		--with-http_flv_module \
		--with-http_mp4_module \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_random_index_module \
		--with-http_secure_link_module \
		--with-http_stub_status_module \
		--with-http_auth_request_module \
		--with-http_xslt_module=dynamic \
		--with-http_image_filter_module=dynamic \
		--with-threads \
		--with-stream \
		--with-stream_ssl_module \
		--with-stream_ssl_preread_module \
		--with-stream_realip_module \
		--with-http_slice_module \
		--with-mail \
		--with-mail_ssl_module \
		--with-compat \
		--with-file-aio \
		--with-http_v2_module \
		--add-module=/usr/src/echo-nginx-module-$ECHO_NGINX_MODULE_VERSION \
		--add-module=/usr/src/fastdfs-nginx-module-$FASTDFS_NGINX_MODULE_VERSION/src \
		--add-module=/usr/src/nginx-eval-module-$NGINX_EVAL_MODULE_VERSION \
		--add-module=/usr/src/ngx_http_redis-$NGX_HTTP_REDIS_VERSION \
	" \
	&& cd /usr/src/nginx-$NGINX_VERSION \
	&& ./configure $CONFIG --with-debug \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& mv objs/nginx objs/nginx-debug \
	&& mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so \
	&& mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
	&& ./configure $CONFIG \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	&& rm -rf /usr/local/nginx/html/ \
	&& mkdir /usr/local/nginx/conf.d/ \
	&& mkdir -p /usr/share/nginx/html/ \
	&& install -m644 html/index.html /usr/share/nginx/html/ \
	&& install -m644 html/50x.html /usr/share/nginx/html/ \
	&& install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
	&& install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so \
	&& install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so \
	&& ln -s /usr/lib/nginx/modules /usr/local/nginx/modules \
	&& strip /usr/sbin/nginx* \
	&& strip /usr/lib/nginx/modules/*.so \
	&& mv /usr/bin/envsubst /tmp/ \
	&& mv /tmp/envsubst /usr/local/bin/ \
	&& yum clean all \
	&& rm -fr /var/cache/yum/*


## some important fast and fast-nginx-module params:
## base_path in tracker.conf
## base_path, store_path0, tracker_server in storage.conf and mod_fastdfs.conf


## FastDFS conf
COPY conf/fdfs/*.* /etc/fdfs/
## nginx conf
COPY conf/nginx/nginx.conf /usr/local/nginx/nginx.conf

COPY start.sh /usr/bin/

#make the start.sh executable 
RUN chmod 777 /usr/bin/start.sh

# port exposed
EXPOSE 22122 23000 23080
VOLUME ["$FASTDFS_BASE_PATH", "/etc/fdfs"] 

ENTRYPOINT ["/usr/bin/start.sh"]
CMD ["tracker"]
