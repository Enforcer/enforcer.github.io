--- 
layout: post
title: On factory_boy - antipatterns & patterns you won't find in the manual
description:
date: 2023-02-09 20:39:07 +0100
published: true 
categories: 
tags: 
lang: 
---

## Meet a good boi - factory_boy

There is a great library that makes it easy to create factories of various objects for tests - [factory\_boy](https://factoryboy.readthedocs.io/en/stable/introduction.html). Chances are you either saw it or used it to insert models into a test database, e.g. with Django or SQLAlchemy:

(example from the docs)

```python
    class UserFactory(factory.django.DjangoModelFactory):
        class Meta:
            model = 'myapp.User'
            django_get_or_create = ('username',)
    
        username = 'john'
    
    # create a new user
    UserFactory(username='jack')
```

What is less obvious, factory\_boy can be also successfully used to create various [Data Transfer Objects](https://en.wikipedia.org/wiki/Data_transfer_object) implemented with e.g. [pydantic](https://docs.pydantic.dev/), [dataclasses](https://docs.python.org/3/library/dataclasses.html) or [attrs](https://www.attrs.org/en/stable/) or even [plain dicts](https://factoryboy.readthedocs.io/en/stable/reference.html#dict-and-list)!

The documentation states it’s meant to replace complex fixtures commonly used with e.g. pytest. In the most straightforward words, fixtures are data needed to be set up in the system under test before we execute the test scenario.

If we have nested objects or use foreign keys, we can for example easily create an order of a user with a specific username:

```python
    OrderFactory(user__username='jack')
```

A double underscore in the keyword argument name means a reference to the nested field.

Cool! However, the docs of this tool (as well as many, many others…) focus on showing off features. They rarely contain examples of patterns & antipatterns.

## Antipatterns & patterns

### Antipattern #1 - Excessive randomization

You might have noticed that when one uses a factory, only a subset of fields need to be passed. Others can be generated or specified explicitly:

```python
    class UserFactory(factory.Factory):
        class Meta:
            model = User
    
        first_name = factory.Faker('name', locale='fr_FR') # random value
        last_name = 'Petain' # specified explicitly
```

There’s nothing wrong with generating fields that are not affecting any business rules or logic. For example, identifiers that are only passed around should be just fine to be generated (e.g. [UUIDs](https://docs.python.org/3/library/uuid.html)).

However, when a given field is taking part in the calculations or some logic and you let factory\_boy use a random value for it, you’re asking for trouble. Two examples when this bit me:

1. random datetimes that were later verified

2. the decimal value used to represent money, which sometimes was negative…

And yes, of course, you can specify some criteria to limit the range of generated values, e.g. specify that random datetime needs to be in the future. The question is whether you’ll be able to notice that and put the constraints in time.

Chances are the tests will work just fine until random values will come out “invalid”. **Having tests failing randomly is one of the worst developer experiences one can have, especially if the test suite passes locally but blows up in the build system used for CI.**

Instead of relying too much on randomization, use stereotype objects with _reasonable_ defaults.

### Pattern #1 - Stereotype objects

So what’s better than relying on random values? Specify them explicitly. Let’s not do that inside the test, especially if it’s not relevant for the scenario:

```python
    def test_accepted_order_cannot_be_accepted_again():
        # user's name is not relevant for that test (see function name)
        order = Order(user__name="Joe", status="ACCEPTED")
```

Instead, we can specify default values on the level of the factory:

```python
    class UserFactory(factory.Factory):
        class Meta:
            model = User
    
        first_name = "Joe" # both values are specified explicitly
        last_name = "Petain"
```

Regarding other part, order’s status, we can also delegate it to the factory. Except that we’ll create a dedicated subclass for this particular stereotype object:

```python
    class OrderFactory(factory.Factory): # general factory
        class Meta:
            model = Order
    
        status = "NEW"
    
    class AcceptedOrderFactory(OrderFactory): # specialized factory
        status = "ACCEPTED"
```

That way, we can have reusable factories for so-called stereotype objects, i.e. instances in a specific state.

### Antipattern #2 - Overusing relations

Since factories are so simple to use, it’s tempting to add forced relations between models, so that we can create everything we need at once, using a single factory.

Even if they are not _directly_ related from the point of view of business requirements.

That’s a slippery slope, leading to the [big ball of mud](https://thedomaindrivendesign.io/big-ball-of-mud/) and other monolithic monsters. Basically all the stuff parents scare children with.

### 

Neglecting modularization in the application takes a toll in many places, including tests. But more on this in one of the following episodes of Pythoneer.guru. Take care!

## Links:

- [Mypy 1.0 released](https://mypy-lang.blogspot.com/2023/02/mypy-10-released.html)

- [Site with EOL for each Python version (3.7 EOL is closing…)](https://endoflife.date/python)

- [Theine](https://github.com/Yiling-J/theine) - in-memory caching with core written in Rustpy

- [EuroPython 2023](https://ep2023.europython.eu/) is gonna take place in Prague, Czech Republic this year

