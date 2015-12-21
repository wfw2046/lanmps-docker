FROM debian:jessie

# persistent / runtime deps
RUN apt-get update && \
    sed -i 's/http:\/\/httpredir\.debian\.org\/debian\//http:\/\/mirrors\.163\.com\/debian\//g' /etc/apt/sources.list && \
    apt-get install -y ca-certificates curl librecode0 libsqlite3-0 libxml2  autoconf file g++ gcc libc-dev make pkg-config re2c --no-install-recommends

ENV PHP_DIR /www/lanmps/php
RUN mkdir -p $PHP_DIR

ENV GPG_KEYS 0BD78B5F97500D450838F95DFE857D9A90D90EC1 6E4F6AB321FDC07F2C332E3AC2BF0BC433CFC8B3
RUN set -xe \
	&& for key in $GPG_KEYS; do \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	done

ENV PHP_VERSION 5.6.16
ENV PHP_FILENAME php-5.6.16.tar.xz
ENV PHP_SHA256 8ef43271d9bd8cc8f8d407d3ba569de9fa14a28985ae97c76085bb50d597de98

# --enable-mysqlnd is included below because it's harder to compile after the fact the extensions are (since it's a plugin for several extensions, not an extension in itself)
RUN buildDeps=" \
		$PHP_EXTRA_BUILD_DEPS \
		libcurl4-openssl-dev \
		libreadline6-dev \
		librecode-dev \
		libsqlite3-dev \
		libssl-dev \
		libxml2-dev \
		xz-utils \
	" \
	&& set -x \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends \
	&& curl -fSL "http://php.net/get/$PHP_FILENAME/from/this/mirror" -o "$PHP_FILENAME" \
	&& echo "$PHP_SHA256 *$PHP_FILENAME" | sha256sum -c - \
	&& curl -fSL "http://php.net/get/$PHP_FILENAME.asc/from/this/mirror" -o "$PHP_FILENAME.asc" \
	&& gpg --verify "$PHP_FILENAME.asc" \
	&& mkdir -p /tmp/$PHP_DIR \
	&& tar -xf "$PHP_FILENAME" -C /tmp/$PHP_DIR --strip-components=1 \
	&& rm "$PHP_FILENAME"* \
	&& cd /tmp/$PHP_DIR \
	&& ./configure \
		--with-config-file-path="$PHP_DIR" \
		--with-config-file-scan-dir="$PHP_DIR/conf.d" \
		--with-mysql=mysqlnd \
        --with-mysqli=mysqlnd \
        --with-pdo-mysql=mysqlnd \
        --with-freetype-dir \
        --with-jpeg-dir \
        --with-png-dir \
        --with-zlib \
        --with-libxml-dir=/usr \
        --with-curl \
        --with-openssl \
        --with-readline \
        --with-recode \
        --with-mcrypt \
        --with-gd \
        --with-openssl \
        --with-mhash \
        --with-xmlrpc \
        --without-pear \
        --with-gettext \
        --with-fpm-user=www \
        --with-fpm-group=www \
        --enable-fpm \
		--disable-cgi \
		--enable-mysqlnd \
        --enable-xml \
        --enable-opcache \
        --disable-rpath \
        --enable-bcmath \
        --enable-shmop \
        --enable-sysvsem \
        --enable-inline-optimization \
        --enable-mbregex \
        --enable-mbstring \
        --enable-ftp \
        --enable-gd-native-ttf \
        --enable-pcntl \
        --enable-sockets \
        --enable-zip \
        --enable-soap \
        --disable-fileinfo \
	&& make -j"$(nproc)" \
	&& make install \
	&& { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $buildDeps \
	&& make clean
RUN ln -s "${PHP_DIR}/bin/php" /usr/bin/php
    && ln -s "${PHP_DIR}/bin/phpize" /usr/bin/phpize
    && ln -s "${PHP_DIR}/sbin/php-fpm" /usr/bin/php-fpm
    && mkdir -p ${PHP_DIR}/etc/

#删除多余文件
RUN rm -rf /root/lanmps-* && \
rm -rf /tmp/* && \
rm -rf /var/log/yum.log && \
rm -rf /var/cache/yum/* && \
rm -rf /var/lib/apt/lists/* && \
rm -rf /usr/share/man/?? && \
rm -rf /usr/share/man/??_*

COPY docker-php-ext-* /usr/local/bin/

##<autogenerated>##
WORKDIR /www/wwwroot/default
COPY php-fpm.conf ${PHP_DIR}/etc/

EXPOSE 9000
CMD ["php-fpm"]
##</autogenerated>##