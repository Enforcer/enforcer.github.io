--- 
layout: post
title: Python type hints are far from perfect. Yet, they are one of the the best things that were added to the language
description:
date: 2023-03-09 19:37:38 +0100
published: true 
categories: []
tags: []
lang: 
---

## Dynamic typing FTW! …or not?

My experience with Python roots back to 2012 with some short learn & experiment episodes before. Enough to say, I remember very well what it was like to work with larger Python codebases that were devoid of any type hints.

Back at the time, I found dynamic typing to be superior to static. That changed after I set out to give a talk on a local mini-conference in which my goal was to persuade the static typing camp that “hey, it’s not so scary and bad in dynamic-land!”. Oh, boy.


![Static versus Dynamic Type Gymnastics](/assets/2023/03/type_gymnastics.png)


The problem was I failed to find any solid proof to support the claim that dynamic typing is as good as static typing. Various articles and StackOverflow threads said otherwise. Eventually, I delivered the talk focusing on differences and how to tame dynamic typing, rather than trying to convince static typing die-hards.

In the aftermath, I started seriously doubting if dynamic typing was the optimal way to go in the projects I worked on. Once Python 3.5 was released, I adopted type hints immediately and NEVER looked back.

## Benefits

Your mileage may vary, but these are things that struck almost immediately:

- super quick navigation through code in both directions (no more grep/ack!)

- brilliant and reliable suggestions from IDE

- catching a certain class of errors long before tests or code runs

- using a lot of kick-ass tools that leverage type hints (think Pydantic)

One note, though - if you are not using a type checker (e.g. mypy) and still writing type hints, you’re lying to yourself. Without validation, they are as dangerous as code comments - once they become outdated, you’ll never know until it bites you.

Also, mypy often silently gives up on default settings - see [mypy is not enough](https://emplocity.com/en/about-us/blog/mypy_not_enough/) for more details.

## Initial friction

For many type hints adopters the new syntax is not the biggest obstacle. **One needs to change the way they write code so it can be easily typed.** Some Python idioms useful with dynamic typing suddenly become a burden.

As with unit tests, in Python you can resort to dark magic and nasty trickery to test/annotate all the strange constructs.

![Floor is rewriting code to be testable](/assets/2023/03/testable.png)

…and that makes you end up with a lot of effort and dubious results.

## New coding style = New Hope?

There are numerous examples of idioms that were absolutely ok and widespread in dynamic, untyped Python but with type hints, they cause extra friction.

### dicts as a mean to pass data

Before type hints, dictionaries flying around were omnipresent. Now, we’re encouraged to use more static approach with dataclasses or more generally speaking - Data Transfer Objects.

### \*args and \*\*kwargs accepting arguments of different types

A lot of libraries resorted to using dynamic `**kwargs` so the arguments can be passed frictionlessly through different layers of abstractions. That’s no longer convenient, type hints encourage us to put everything explicitly. And rethink the function that accepts too many arguments, by the way.

### decorators

That one was tricky for a long time to get right in mypy, but [it seems that it’s finally supported](https://mypy.readthedocs.io/en/stable/generics.html#declaring-decorators). Still, any trickery in decorators may cause issues in annotating it so the type checker doesn’t complain.

## Ecosystem is maturing… but we still have a long way to go

Few days ago I saw a [tweet from Armin Ronacher](https://twitter.com/mitsuhiko/status/1632675582176526337):

![Typing not being helpful in Django / Sentry?](assets/2023/03/armin.png)

Armin is the creator of Flask framework and a contributor to many important initiatives in the Python world. Here, he’s speaking from the perspective of Sentry’s Principal Architect role. The insights he’s sharing are very interesting and also a bit alarming for those who are uncertain if type hints are worth the shot.

For context, Sentry is not only a SaaS, but also open source project written in Django. Other people on Twitter even pointed out that Django may be the problem. There may be some truth in that - Django predates typing era. It was written when type annotations were not a thing.

## Tools immaturity or bad habits? Or both?

Armin shared also an example:

![Example](/assets/2023/03/armin2.png)

I dug t[his fragment up from Sentry’s source code](https://github.com/getsentry/sentry/blob/93a3aabb66034dcd63c55ac5e8c15d6d094a813f/src/sentry/release_health/metrics.py#L548) and I’ll tell you what I think is the problem here. To not set up the entire project, I prepared a simplified version (the snippet is complete):

```python
    from datetime import date
    from typing import TypedDict
    
    
    FormattedIsoTime = str
    
    
    class _TimeBounds(TypedDict):
        sessions_lower_bound: FormattedIsoTime
        sessions_upper_bound: FormattedIsoTime
    
    
    class _NoTimeBounds(TypedDict):
        sessions_lower_bound: None
        sessions_upper_bound: None
    
    
    ReleaseSessionsTimeBounds = _TimeBounds | _NoTimeBounds
    
    
    def example(min_date: date | None, max_date: date | None) -> ReleaseSessionsTimeBounds:
        # There was a lot of code in this function - I skipped it
        # for the example's sake
    
        if min_date is not None and max_date is not None:
            return { # type: ignore
                "sessions_lower_bound": min_date.isoformat(),
                "sessions_upper_bound": max_date.isoformat(),
            }
        else:
            return { # type: ignore
                "sessions_lower_bound": None,
                "sessions_upper_bound": None,
            }
```

At the first glance, the type annotation is fine. In both possible cases, we return a dictionary with `session_lower_bound` and `session_upper_bound` keys. In one case both values are strings, in another - `None`s.

Now if you run it under mypy (I have 0.982 version installed) it says:

    Success: no issues found in 1 source file

Huh, let’s remove those pesky `# type: ignore`. After doing it, we’ll see the actual errors:

    typing_fun/ __init__.py:26: error: Type of TypedDict is ambiguous, could be any of ("_TimeBounds", "_NoTimeBounds") [misc]
    typing_fun/ __init__.py:26: error: Incompatible return value type (got "Dict[str, str]", expected "Union[_TimeBounds, _NoTimeBounds]") [return-value]
    typing_fun/ __init__.py:31: error: Type of TypedDict is ambiguous, could be any of ("_TimeBounds", "_NoTimeBounds") [misc]
    typing_fun/ __init__.py:31: error: Incompatible return value type (got "Dict[str, None]", expected "Union[_TimeBounds, _NoTimeBounds]") [return-value]
    Found 4 errors in 1 file (checked 1 source file)

That means mypy wasn’t able to infer if the dict returned will have Nones or strings as values. Even though it may look like it should - I don’t see any mistake here. What we can always do is to help mypy:

```python
    def example(min_date: date | None, max_date: date | None) -> ReleaseSessionsTimeBounds:
        # There was a lot of code in this function - I skipped it
        # for the example's sake
    
        if min_date is not None and max_date is not None:
            time_bounds_result: _TimeBounds = {
                "sessions_lower_bound": min_date.isoformat(),
                "sessions_upper_bound": max_date.isoformat(),
            }
            return time_bounds_result
        else:
            no_time_bounds: _NoTimeBounds = {
                "sessions_lower_bound": None,
                "sessions_upper_bound": None,
            }
            return no_time_bounds
```

…or be even more explicit:

```python
    def example(min_date: date | None, max_date: date | None) -> ReleaseSessionsTimeBounds:
        # There was a lot of code in this function - I skipped it
        # for the example's sake
    
        if min_date is not None and max_date is not None:
            return _TimeBounds(
                sessions_lower_bound=min_date.isoformat(),
                sessions_upper_bound=max_date.isoformat(),
            )
        else:
            return _NoTimeBounds(
                sessions_lower_bound=None,
                sessions_upper_bound=None,
            )
```

Is the code doing the same thing in all the cases? Yes. Is it written differently, in a less obvious way (that’s subjective)? Certainly, at least from the point of view of the author.

However, in this case, all we actually need to do is to update mypy. If we run it in version 1.1.1 (the newest available at the moment of writing) on the original code all we’ll see is:

    typing_fun/ __init__.py:26: error: Unused "type: ignore" comment
    typing_fun/ __init__.py:31: error: Unused "type: ignore" comment
    Found 2 errors in 1 file (checked 1 source file)

Turned out this was a bug/missing feature and was recently implemented.

I saw this already a few times. **Usually, I prefer to rewrite the code to be more mypy-friendly.**  **Putting** `#type: ignore` **should really be the last resort.** I recommend this approach to anyone who wishes to take full advantage of type hints.

## Was Django an issue here?

I also tracked down how the output of the function was used - and it turned out to be returned from some endpoint as JSON as part of old-plain untyped dict. You could say that type annotations were just thrown away at that point. (facepalm).

Django simply doesn’t take any advantage of type annotations - it would be more interesting to see this logic rewritten with [Django Ninja](https://django-ninja.rest-framework.com/) or FastAPI/Pydantic.

On the other hand, we can see either large and widely used projects such as SQLAlchemy managed to adopt type annotations - why not Django at some point? Would that still be Django, though?

## Wrapping up

The same question goes for coding style. It has to be changed completely in order to fully reap the benefits of typed Python.

The stronger dynamic typing habits a developer has, the more such idioms are used in the code base, and the more a tool or framework relies on them - the more friction and issues one will face.

