--- 
layout: post
title: Running tests in parallel with pytest
description:
date: 2023-03-16 19:36:22 +0100
published: true 
categories: []
tags: []
lang: 
---

IT projects under active development tend to grow a lot. So their test suites. It is only a matter of time until you’ll be looking for ways to speed up the execution of tests.

## Metrics first

There is a saying _you can't manage what you can't measure_. There’s something about it; it would be great to have some tangible metrics first. Personally I use mostly following two:

- time from start to finish of a single unit test

- total time of running the entire test suite.

The first one is important to maintain TDD cycles short & sweet. We’ll focus on the latter today and one particular technique to optimize it.

## Total time of running the entire test suite - how to measure it?

pytest prints the total time to the console after it finishes:

    ====== 14 passed, 2 warnings in 4.53s ======

## Techniques for optimizing the total execution time

- reusing data/fixtures that are not changed between tests

- profiling and removing bottlenecks in the slowest tests

- adjusting QA strategy to rely more on unit tests and e.g. typing than functional tests

- running tests in parallel

In this post we’ll focus only on the last one.

## Few facts about running tests in parallel

### It can actually slow down test execution instead of speeding things up

There’s a certain overhead for running tests in parallel and synchronising workers that run individual tests. For a test suite that’s full of unit tests that do not use e.g. database, benefits can be negligible. It is safe to say that running 1000 unit tests will be faster without parallelization.

### It's unforgiving for poor tests

If tests are not properly isolated, you’ll only see tons of exceptions and random failures. Tests relying on each other can work when they are run one after another, but if e.g. they modify the same thing and will be executed in parallel, things will blow up.

If you want to make sure you’re tests are independent, you can try out [pytest-random-order](https://pypi.org/project/pytest-random-order/). It will simply run individual tests in a randomized way and if there are dependencies between tests, it will surely find them. **It’s a good first step if you’re thinking about parallelization but you’re worried about test suite quality.**

### The earlier you start doing it, the easier it will be

On the other hand, if you start a new project and enforce running tests in parallel from the start (even though it may be slower…for some time) you’ll face any isolation issues much sooner - so there will be pressure to fix it. The later in the project lifecycle you try to parallelize tests, the harder it can get.

## Running tests in parallel - let’s start

The first step is to install pytest plugin - [pytest-xdist](https://pypi.org/project/pytest-xdist/):

    pip install pytest-xdist

Now we’re ready to run tests in parallel. We can either specify the number of workers explicitly using `-n` parameter, e.g. 4:

    pytest -n 4 tests/

…or let pytest-xdist determine it using available CPUs/cores:

    pytest -n auto tests/

If you’re lucky (or have a great test suite with nicely isolated tests) that should be it.

    gw0 [14] / gw1 [14] / gw2 [14] / gw3 [14]
    ..............
    ==== 14 passed, 2 warnings in 4.06s ===

In my case, there was a boost of 0.47 s or 10%. Of course the bigger the test suite, the bigger the potential gain.

## worker\_id fixture

pytest-xdist provides a special fixture that can be used to further customize tests and other fixtures.

If you run tests without parallelization, worker\_id will have a value of `“master”`.

```python
    def show_worker_id(worker_id: str) -> None:
        print(worker_id) # will be "master" if one runs pytest without -n
```

However, when you run tests with multiple workers, then in each worker\_id there will be other values for the fixture:

    pytest -n 2 tests/


```python 
    def show_worker_id(worker_id: str) -> None:
        print(worker_id) # will be "gw0" or "gw1" depending on the worker
```

pytest-xdist will be putting the value of `“gw<worker number>” `into the fixture. This is neat because allows taking isolation to the next level…

## When you need isolation on the database level

Consider a simple case - your tests modify the same rows in the database and they are not ready to be parallelized. However, they work just fine when run sequentially. What we can do is guarantee that separate workers will get their separate test databases! BTW, that’s what [pytest-django](https://pytest-django.readthedocs.io/en/latest/)does.

So to start with, let’s say we have a fixture that’s going to set up test database as an SQLite file:

```python
    @pytest.fixture(scope="session", autouse=True)
    def db_for_tests(tmp_path_factory: TempPathFactory) -> Iterator[None]:
        # create temporary directory and file for the test database
        # it will be automatically removed after test suite is finished
        tmp_dir = tmp_path_factory.mktemp("db_for_tests")
        test_db_file = tmp_dir / "test_db.sqlite"
    
        # create SQLAlchemy's engine that uses test database
        test_db_engine = create_engine(f"sqlite:///{test_db_file}")
        # reconfigure session_factory so code under tests uses our test db
        session_factory.configure(bind=test_db_engine)
    
        # create all tables
        Base.metadata.create_all(test_db_engine)
        yield
        # disconnect and say goodbye
        test_db_engine.dispose()
```

Now, the test database file name is calculated on this line

    test_db_file = tmp_dir / "test_db.sqlite"

We can append `worker_id` value to get a unique database per worker!

```python
    @pytest.fixture(scope="session", autouse=True)
    def db_for_tests(
        tmp_path_factory: TempPathFactory, worker_id: str
    ) -> Iterator[None]:
        tmp_dir = tmp_path_factory.mktemp("db_for_tests")
        test_db_file = tmp_dir / f"test_db_{worker_id}.sqlite"
```

Of course in this example that would work on multiple workers as well because each gets its own temporary directory, but what’s important here is the technique.

We could use it for creating separate test databases on e.g. single PostgreSQL or MongoDB instance.

## When you need isolation on RabbitMQ level

RabbitMQ is special because it has something built-in - [virtual hosts](https://www.rabbitmq.com/vhosts.html). So you can technically use `worker_id` fixture to create dedicated virtual hosts for each worker, reconfigure the application to use that particular vhost and remove it afterwards.

```python
    @pytest.fixture(scope="session", autouse=True)
    def configure_vhost(worker_id: str, config: Config) -> Iterator[None]:
        test_vhost = config.rabbitmq.vhost + worker_id
        create_vhost(test_vhost)
        config.rabbitmq.vhost = new_vhost
        yield
        remove_vhost(test_vhost)
```

## When you need isolation on Redis

Redis has a feature of separate databases, numbered like 0, 1, 2 etc. So you can technically prepare your fixtures so the application in each worker uses a separate database.

```python
    @pytest.fixture(scope="session", autouse=True)
    def configure_redis_db(worker_id: str, config: Config) -> None:
        if worker_id == "master": # special case for no parallel tests run
            test_db = 0
        else:
            # for parallel tests, worker_id assumes value of "gw0", "gw1",
            # "gw2" and so on
            test_db = int(worker_id.replace("gw", ""))
    
        config.redis.db = test_db
```

Warning: not all Redis features are isolated, e.g. [PUB/SUB is global](https://redis.io/docs/manual/pubsub/#database--scoping).

## When you need isolation on Kafka…and others

It may happen that a given database/tool doesn’t have a way to isolate test workers. Or for example, your application already uses multiple virtual hosts on RabbitMQ or Redis databases - what to do then?

Your last resort will be to prefix names of all topics (on Kafka), queues and exchanges (on RabbitMQ) or key names (on Redis). That will be a bit more invasive, though. Your application will have to be adjusted in a way prefixes can be set in fixtures.

## Summary

It is never hard to pip-install another library, but running tests in parallel is slightly more complex. It is definitely easier when the test suite is maintained in a good shape and tests are properly isolated from each other.

## Links

- [pytest-xdist](https://pypi.org/project/pytest-xdist/)

- [pytest-random-order](https://pypi.org/project/pytest-random-order/)

- [Speeding Up Django Test Suites](https://testandcode.com/135)

