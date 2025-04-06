DIRECTORY = $(shell pwd)

.PHONY: init
init:
	docker build -t blog_jekyll .

.PHONY: start
start:
	docker run -p 4000:4000 -p 35729:35729 -it -v $(DIRECTORY):/blog blog_jekyll bundle exec jekyll s --watch --force_polling --livereload --host 0.0.0.0

.PHONY: test
test:
	docker run -p 4000:4000 -p 35729:35729 -it -v $(DIRECTORY):/blog blog_jekyll bundle exec htmlproofer _site --disable-external --ignore-urls "/^http:\/\/127.0.0.1/,/^http:\/\/0.0.0.0/,/^http:\/\/localhost/"

