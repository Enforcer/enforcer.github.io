--- 
layout: post
title: Why so pedantic about pydantic or validate only at the edge of the app
description:
date: 2023-02-16 21:22:46 +0100
published: true 
categories: []
tags: []
lang: 
---

## Pydantic is wonderful

Let’s admit it - [pydantic](https://docs.pydantic.dev/) is one of the best things that happened to the Python ecosystem in recent years. For me, it’s like a dream that come true - I suspected there will be a lot of awesome tools built a top of type annotations and pydantic is definitely one of the most widely adopted ones.

What is more, pydantic enabled other libraries and frameworks to exist - such as [FastAPI](https://fastapi.tiangolo.com/).

## Pydantic is also for DTOs… or not really?

While Pydantic’s main role is to do data conversion (and validation), it sometimes also took the role of implementing Data Transfer Objects.

DTOs are simple data structures used solely for passing data around - instead of untyped dicts that all old Python kids used to use (and abuse).

```python
    from pydantic import BaseModel
    
    class BidDto(BaseModel):  
        auction_id: AuctionId
        bidder_id: BidderId
        amount: Money
    
    # now cool kids use this...
    bid = BidDto(auction_id=auction_id, bidder_id=bidder_id, amount=amount)
    
    # instead of
    bid = {
        'auction_id': auction_id,
        'bidder_id': bidder_id,
        'amount': amount
    }
```

Profits are obvious - support from IDE (hints!) and static code validation with mypy, pyre, pyright etc

However, bear in mind that pydantic does more than simply generating ` __init__ ` for us - it also takes care of data conversion and validation. And that’s taking CPU cycles. Also, it can raise exceptions.

## Any alternatives for Python DTOs?

There surely are many, but I’ll name my top two’s - attrs and dataclasses. They look very similar:

```python
    from dataclasses import dataclass
    from attrs import define
    
    @define(frozen=True)
    class PersonAttrs:
        name: str
        age: int
    
    
    @dataclass(frozen=True)
    class PersonDataclass:
        name: str
        age: str
    
    # usage
    PersonAttrs(name='Sebastian', age=30)
    PersonDataclass(name='Sebastian', age=30)
```

Out of those two, I prefer `attrs` thanks to one important feature - handling of private fields. `dataclasses` can’t do that:

```python
    @define(frozen=True)
    class PersonEncapsulated:
        _name: str
        _age: int
    
    
    # attrs is translating "name" to "_name" field.
    # Single underscore are used for encapsulation in Python (by convention only)
    PersonEncapsulated(name='Peter', age=31)
    # PersonEncapsulated(_name='Peter', _age=31)
```

The main difference between using dataclasses or attrs versus pydantic is that those former won’t do any conversion/validation. If you pass `int` for `str` field, you’ll have int there. However, that’s why type checkers like mypy are for - to notice that kind of mistake BEFORE the code runs.

## Why Pydantic IS NOT a replacement for DTOs?

While it’s crucial to validate and convert data that’s coming into the system, e.g. in HTTP requests body, we don’t need _that kind_ of security beyond the entry point. That’s why we have those types and type checkers; once we validate the data and make sure we don’t mutate it (`frozen=True`), we can be sure it’s going to be fine.

For simply passing data around, rather use attrs/dataclasses. Why? There are two reasons.

### Issue #1 - performance hit

Although [pydantic is fast](https://field-idempotency--pydantic-docs.netlify.app/benchmarks/) and [is going to be even faster soon](https://docs.pydantic.dev/blog/pydantic-v2/), you don’t really need to use extra CPU cycles so it can run its validation logic when not needed.

BTW I know there’s a [way to create pydantic objects and bypass the validation/conversion part](https://docs.pydantic.dev/usage/models/#creating-models-without-validation), but I’d rather not expect everyone to remember when to use which method of creation.

It’s fair to say that performance is not a huge concern in many projects, but there are some where it actually matters a lot.

## Issue #2 - exceptions in the middle of the logic

When there’s a conversion or validation exception at the edge of the application, e.g. on the API - it’s fine. After all, we fail fast and let client know they send something unexpected.

However, when we build a pydantic object somewhere beyond the API, e.g. in application or domain layer to pass something and we end up with an exception, it’s a different kind of problem. We no longer have an issue with incoming data, but rather there are some bugs in our logic.

Having a type-related exception in business code is rather unrecoverable. The better approach is to rely more on static typing and mypy (or other type checkers). And use dataclasses/attrs, because mypy has our back.

## Type-check (and convert) data only at the edge of the application

Personally, I don’t see a point in libraries such as [typeguard](https://pypi.org/project/typeguard/)that perform runtime checks of types. Some validation is required of course, but if we can do it with incoming data, how we ended up in a position where we cannot trust our logic to operate on valid types…?

Instead of risking getting nasty exceptions in the runtime, it’s best to eliminate this kind of error long before the code runs with static code analysis, mypy and [strict config](https://careers.wolt.com/en/blog/tech/professional-grade-mypy-configuration).

## Links

- [awesome-python-typing](https://github.com/typeddjango/awesome-python-typing) - more goodies that use Python type hints!

- [Python trends in 2023](https://blog.jerrycodes.com/python-trends-in-2023/)

- [7 ways to implement DTOs in Python and what to keep in mind](https://dev.to/izabelakowal/some-ideas-on-how-to-implement-dtos-in-python-be3)

- [Professional-grade mypy configuration](https://careers.wolt.com/en/blog/tech/professional-grade-mypy-configuration)

