--- 
layout: post
title: Writing custom exceptions in Python - what you need to know
description: 
date: 2023-03-23 17:47:25 +0100
published: true 
categories: []
tags: []
lang: 
---

Exceptions are standard way of error handling in Python. Their using, i.e. raising and catching using `except` keyword is one of the cornerstone skills of a Pythonista. By the way, in other programming languages raising an exception is often called throwing.

In Python, [there are many built-in exception classes](https://docs.python.org/3/library/exceptions.html#exception-hierarchy). You shouldn’t raise them on your own, though (in most cases).

## Risk of catching built-in exceptions

When you raise an exception, someone else (maybe also you) will catch it somewhere else. If this is a built-in exception, you can’t be sure if it will reach your handling or it will be _swallowed_ before it reaches the code you wrote for handling.

_Swallowing_ an exception means essentially catching it just to do…nothing. Maybe logging the fact, but that’s it. Another name for this “pattern” is exception silencing.

So what should you do instead?

## Writing your own exception classes

Custom exception classes won’t be caught accidentally (that easily).

### Exception class name should express what happened

It’s extremely important to put meaningful information in the exception class name.

```python
    class SubscriptionAlreadyCancelled(Exception):
         pass
    
    
    class CantModifyPastSprint(Exception):
        pass
```

The best source of ideas for names is the domain of the project you’re working on. That way you can easily tell what actually happened and sometimes even know what was attempted.

When you look at the built-in exceptions you’ll notice many of them has `Error` suffix, e.g. `KeyError` or `IndexError`. There are two schools of thought on that topic. One says to append `Error` or `Exception` to the name and the other advice against it. Personally, I’m in the second camp. Unless I write a base class for other exceptions classes but we’ll get to it in a minute.

Your project won’t fail if you choose one way or another, though. I’d say it’s a matter of taste - just choose one approach and follow it.

### Hierarchies

One of the most powerful features of exceptions is that when we organize them into an inheritance hierarchy, we can catch all of the subclasses (and their subclasses and so on) by writing except SuperclassName.

For example, consider this subtree of built-in exceptions:

    ├── ArithmeticError
        ├── FloatingPointError
        ├── OverflowError
        └── ZeroDivisionError

When one writes except `ArithmeticError`, they’ll also get its exception subclasses:

```python
    try:
        foo()
    except ArithmeticError:
        # if foo raises. e.g. OverflowError, we'll also catch it here
```

As a reminder, when we want to be more specific, e.g. handle `OverflowError` in a special way, but provide a generic path for the remaining two subtypes of `ArithmeticError`, we need to put specific except higher.

They are checked from the top and after the first match, processing stops:

```python
    try:
        foo()
    except OverflowError:
        print("😱")
        sys.exit(-1)
    except ArithmeticError:
        sys.exit(0)
```


All programming languages with exceptions support this, e.g. Java, PHP or C# (shame on you, JavaScript/TypeScript!).

### Multi-inheritance versus exception classes

It is technically possible to have an exception class that inherits from two base classes:

```python
    class MoneyLostException(Exception):
        pass
    
    
    class DomainException(Exception):
        pass
    
    
    
    class WeNoLongerHaveYourCoat(MoneyLostException, DomainException):
        pass
```

I advise against it, though. Say we’re interested in catching both base exception classes:

```python
    try:
        raise WeNoLongerHaveYourCoat()
    except MoneyLostException:
        print("Money lost!") # this will execute
    except DomainException:
        print("Domain exception, dude") # this won't run
```

In this example, only one handling code will execute because it will match.

### Useful hierarchy example

It makes sense to introduce hierarchies when we can apply different handling strategies. For example, errors that can be shown to users and those that can’t.

```python
    class PresentableException(Exception):
        MESSAGE: ClassVar[str]
    
    
    class InnerException(Exception):
        pass
    
    
    class PaymentFailed(PresentableException):
        MESSAGE: ClassVar[str] = "Your payment was unsuccessful"
    
    
    class CantReachThatFlakyMicroservice(InnerException):
        pass # show some generic message, e.g. please try again later
```

This can be actually pretty handful, because many web frameworks support custom handling of exceptions and respect hierarchies.

### Support in frameworks

For example, you can have one generic handler for `PresentableException` and its subclasses:

```python
    # Hierarchy of exceptions, nothing you haven't already seen
    class PresentableException(Exception):
        MESSAGE: ClassVar[str]
    
    
    class PaymentFailed(PresentableException):
        MESSAGE: ClassVar[str] = "Your payment was unsuccessful"
    
    
    @app.get("/")
    def some_view():
        raise PaymentFailed() # simulation of an erroneous situation
    
    
    @app.errorhandler(PresentableException) # general error handler
    def handle_presentable_exception(e):
        return {"success": False, "message": e.MESSAGE}
```

A common and realistic scenario is for example to handle authentication errors in a common way, e.g. `YouCantCancelMeetingThatsNotYourOwn` inheriting from `AuthenticationError`. We could for example have a generic handler that will be responding with a 403 HTTP error.

## But should exceptions be actually used?

### Exceptions (handling) have cost

When an exception is thrown in C++ or Java, the thread in which it happened halts to run so-called stack unwinding. To simplify it a bit, the program traverses stack frames up until it finds a matching `catch` block. If it finds none, the program crashes.

As you can imagine, the more layers (or stack frames to be more precise) the program needs to traverse, the longer the process will take. In Python, a similar thing happens but due to the language specifics, it is much slower than in C++ or Java.

Before Python 3.11 even just the sole fact of having `try…except` a block without any exception raised had an overhead! See [Issue 40222](https://bugs.python.org/issue40222) for more details

Even though exceptions do cost, it shouldn’t be your main concern. Unless high performance is actually important in your project - but then what are you doing in Python? 😁). The biggest issue with exceptions is code design.

### Is the situation actually…exceptional?

Undoubtedly, it makes sense to use exceptions for cases that _shouldn’t_ happen - e.g. some action was taken but the user interface doesn’t directly allow it. For example, trying to cancel a calendar meeting that’s not owned by a user that tries to do it. The offender shouldn’t even see it. (Let’s assume we have filtering implemented).

On the other hand, when we deal with an undesired situation but one that can normally happen (and happens in a significant % of cases) then instead of raising an exception it makes sense to just return a result of an action and handle it accordingly:

```python
    def bid_on_auction(...) -> None:
        result = auction.bid()
        if result.winning:
            send_congratulations_email()
        elif not result.winning:
            send_try_again_email_with_current_price(result.price)
```

That way we can be more explicit in handling and modelling concrete scenarios in the code.
