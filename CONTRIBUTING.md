# Running locally via Docker or compatible env

```bash
docker run -p 4000:4000 -it -v (pwd):/blog -w /blog ruby:3.2 bash
bundle install
bundle exec jekyll s --host 0.0.0.0
```
