--- 
layout: post
title: Do you need dependency injection in Python?
description:
date: 2023-04-06 20:16:52 +0100
published: true 
categories: 
tags: 
lang: 
---

## What’s a dependency?

Consider the following snippet of code, coming from one of the projects on my Github:

```python
    @router.post("/items")
    def add(data: AddItemData, user_id: UUID = Header()) -> Response:
        items = Items()
        items.add(**data.dict(), owner_id=user_id)
        session.commit()
        return Response(status_code=204)
```

A dependency is another class, database connection or Unit Of Work (SQLAlchemy’s session) like in this example.

Also, when e.g. you work with Django and import `from django.conf import settings`, then read some value from settings object, you’re also making it your dependency:

```python
    from django.conf import settings
    
    
    class MyCode:
        kwargs = {}
    
        if not settings.USE_SSL_WITH_MONGO: # there it is, lurking in the shadows!
            kwargs["ssl"] = True
            kwargs["ssl_cert_reqs"] = ssl.CERT_NONE
```

Any non-trivial program that’s not a script in a single file WILL have some dependencies. And they will be used across multiple files.

Somehow, we need to supply them whenever they are needed:

```python
    class ItemsRepository:
        def add(self, item: Item) -> None:
            session = ? # where does it come from...?
            session.add(item)
            session.flush()
```

## Dependencies are pain in the neck…

…when writing & maintaining tests. Especially, if they connect to external systems or cause side effects. Example side effects are sending requests to 3rd party APIs or inserting rows into a database.

Where’s the problem? Usually, we can’t (or don’t want to) use the actual side-effect-causing stuff while testing the code, so we need to replace it/stub it.

It becomes tricky, if our management of dependencies comes down to creating them dynamically in other Python modules and then simply importing them whenever we need:

```python
    # mongo.py
    from pydantic import BaseSettings, MongoDsn
    from pymongo import MongoClient
    
    
    class MongoSettings(BaseSettings):
        dsn: MongoDsn = "mongodb://localhost:27017"
    
    
    _settings = MongoSettings()
    
    client = MongoClient(_settings.dsn)
    
    
    # other_code.py
    from mongo import client
    
    def foo():
        ...
        client.do_something(...) # how do I test `foo` with this fella...?
```

## Dependencies considerations

In every non-trivial project there are a couple of things to consider when dealing with dependencies, these are:

### Lifetime

When a dependency is created? When it is no longer needed and can be destroyed?

### Construction and potentially recursive resolution of dependencies

What do I need to instantiate a dependency? Where can I get this from? What do I do if my dependency requires another dependency etc?

### Reconfiguration

There may be a need to use different configurations e.g. in tests or in another environment. For example, in staging, we might want to use another implementation of the [Gateway pattern](https://martinfowler.com/articles/gateway-pattern.html) that makes it possible to use a certain 3rd party vendor’s API.

## Dependency lifetime

### Once - Singleton

There are cases when our dependency is stateful, thread/coroutine-safe and can be created once and safely reused. That’s the case with `pymongo.Client` class.

We can create it once and reuse it in the program. So technically, a lifetime of such a dependency is the same as a Singleton.

We may create an instance eagerly while the project loads up or do it on first use (lazily). That doesn’t change the fact we need to create it once and actually, we don’t have to bother with deleting it later - it can die with the program.

Other examples from popular libraries are:

- aiohttp.ClientSession

- SQLAlchemy’s engine

### Abusing modules for getting singleton dependencies

You’ve seen already how we can get a dependency with Singleton lifetime - without extra libraries or any other gimmicks - just use modules!

```python
    from pydantic import BaseSettings, MongoDsn
    from pymongo import MongoClient
    
    
    class MongoSettings(BaseSettings):
        dsn: MongoDsn = "mongodb://localhost:27017"
    
    
    _settings = MongoSettings()
    
    client = MongoClient(_settings.dsn)
```

Module in Python also has a semantic of a singleton - it’s created once, lazily - upon import. Once imported, it will be memorized in `sys.modules` and won’t be imported again, unless you force it.

Good luck though with testing that and dealing with potential side effects during import. Instagram has [an excellent blog post](https://instagram-engineering.com/python-at-scale-strict-modules-c0bb9245c834) on how such an (anti)pattern damages their work with a large Python code base.

### Request-scoped dependencies

Oftentimes, we’d like to reuse the same dependency instance throughout the entire HTTP request or while handling a message from the queue.

Such an example is SQLAlchemy’s [Session](https://docs.sqlalchemy.org/en/20/orm/session_basics.html) object. It implements [the Unit Of Work pattern](https://martinfowler.com/eaaCatalog/unitOfWork.html) and tracks all changes on database models we fetched so it can later apply those changes when we tell it to `flush`.

### Resorting to thread-locals to get request-scoped dependencies

Back in the day before asyncio become popular, using a mechanism of [thread-local](https://docs.python.org/3/library/threading.html#thread-local-data) was a way to go in Python. This was very popular in e.g. Flask.

Since every request was handled by another thread (one thread handled one HTTP request at a time) it meant that if we could attach some data to the current thread, it would also be specific to the HTTP request the thread is handling.

SQLAlchemy even has [scoped\_session](https://docs.sqlalchemy.org/en/20/orm/contextual.html#unitofwork-contextual) that by default uses thread local to provide such a separation. The manual page about that also contains a warning:

> The `scoped_session` registry by default uses a Python `threading.local()` in order to track `Session` instances. **This is not necessarily compatible with all application servers**

This incompatibility mentioned nowadays applies mostly to asyncio, so this makes it a no-go approach for many frameworks, e.g. FastAPI when used in async mode.

Also, `scoped_session` (or similar integrations) provides less than one might expect - one is still responsible for starting the transaction or closing the session after the request was handled.

### On-demand dependencies

Finally, we might have some dependencies that are usable in a single function/method and after that can be thrown away.

It should be enough to just create them, but still, we need somehow to have the data required to create an instance…

We could resort to using factory functions:

```python
    # dependency.py
    from django.conf import settings
    
    def create_dependency():
         return Dependency(settings.USERNAME, settings.PASSWORD)
```

Such a function hides some complexity, but we could do better.

## IoC containers are for managing dependencies

Now, there is a group of libraries created to deal with dependencies - their lifetime, construction and recursive resolution of subdependencies.

Such tools are:

- [lagom](https://lagom-di.readthedocs.io/en/latest/) (my favourite! ♥️)

- [dependency injector](https://python-dependency-injector.ets-labs.org/)

- [injector](https://injector.readthedocs.io/en/latest/)

### Lifetime management

Dealing with a dependency’s creation and destroying time is a first-class concept. Example from lagom docs:

> You may have dependencies that you don't want to be built every time. Any dependency can be configured as a singleton without changing the class at all.
> 
> container[SomeClassToLoadOnce] = SomeClassToLoadOnce("up", "left")
> 
> alternatively if you want to defer construction until it's needed:
> 
> container[SomeClassToLoadOnce] = Singleton(SomeClassToLoadOnce)

Often, different dependencies’ lifetimes’ strategies are called _scopes_. This is not so common in the Python tools I mentioned, though. Only injector uses that name.

Lagom uses internally “temporary singletons” for e.g. integration with FastAPI and request-scoped dependencies.

### Recursive dependency resolution

Let’s say we have a class `Items` that requires `ItemsRepository`:

```python
    class Items:
        def __init__ (self, repository: ItemsRepository) -> None:
            self._repository = repository
```

The repository needs SQLAlchemy’s `Session`:

```python
    class ItemsRepository:
        def __init__ (self, session: Session) -> None:
            self._session = session
```

When we need to use `Items` in e.g. API view does it mean we have to assemble it all manually…?

```python
    @router.post("/items") def add(
        data: AddItemData,
        user_id: UUID = Header(),
        session: Session = Depends(get_session),
        items: Items = Injects(Items),
    ) -> Response:
        # assembling starts here...
        session = ScopedSession()
        repository = ItemsRepository(session=session)
        items = Items(repository=repository)
        # ...and it ends here    
    
        items.add(**data.dict(), owner_id=user_id) session.commit()
        return Response(status_code=204)
```

Not to mention that if `Items` class is needed in multiple places, we’re gonna have to repeat the logic of assembling 🤮.

Not to worry! Lagom can handle it just fine with MINIMAL help:

```python
    from lagom import Container
    from sqlalchemy.orm import Session
    
    from my_code.db import ScopedSession
    
    container = Container()
    container[Session] = lambda _: ScopedSession()
```

After that, we can ask `container` to build Items for us and it will recursively traverse the tree of dependencies and will create it for us.

```python
    items = container[Items]
```

Yay! What happens, step-by-step:

1. Lagom checks if it has some special instructions for instantiating `Items`, maybe it’s a singleton?

2. The same logic is executed for `ItemsRepository` - just to find out we need a `Session`

3. Finally, Lagom finds that `Session` has special handling - it needs to call `lambda _: ScopedSession` to get an instance

4. Lagom uses that factory to build `Session`, then passes it into `ItemsRepository` and then finally assembles `Items` instance!

### And what if we need to reconfigure container e.g. in tests?

Then we can rely on built-in features. E.g. Lagom’s integration with FastAPI has a utility function called override\_for\_tests that uses a familiar construct of context manager:

```python
    def test_something():
        client = TestClient(app)
        with deps.override_for_test() as test_container: # here!
            # FooService is an external API so mock it during test
            test_container[FooService] = Mock(FooService)
            response = client.get("/")
    
        assert response.status_code == 200
```

☝️ That snippet comes from [Lagom docs](https://lagom-di.readthedocs.io/en/latest/framework_integrations/#fastapi).

## Recipe for a Python app conscious about dependencies

When booting up the app:

- read & validate configuration first (to fail fast if something’s wrong!)

- assemble application’s IoC container, passing settings where necessary

- Don’t use the `container` directly! (Service Locator anti-pattern)

- Utilise scopes when it makes sense

## …But do you need it?

![Bugs Bunny says no](assets/2023/03/no.png)

No.  
Unless you want to get out-of-the-box:  
- lifetime management as a first-class citizen  
- recursive dependencies resolution management  
- the ability to grab any subgraph of objects and test it  
- the ability to reconfigure the application easily (other environments, tests)

