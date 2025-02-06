FROM ruby:3.2
RUN mkdir /blog
ADD Gemfile Gemfile.lock /blog/
WORKDIR /blog
RUN bundle install

