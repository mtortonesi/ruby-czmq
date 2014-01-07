# ruby-czmq

ruby-czmq is my attempt at building a Ruby bindings gem for the
[CZMQ](http://czmq.zeromq.org/) library.

ruby-czmq realizes a convenient and relatively elegant API on top of the
FFI-based [ruby-czmq-ffi](https://github.com/mtortonesi/ruby-czmq-ffi) gem,
which provides low-level bindings to CZMQ and works on all the main Ruby VMs:
YARV/MRI, JRuby, and Rubinius.


## Motivation

One could wonder whether there was actually the need for a third gem (in
addition to [ffi-rzmq](https://github.com/chuckremes/ffi-rzmq) and the more
outdated and YARV/MRI-specific [rbzmq](https://github.com/zeromq/rbzmq))
providing Ruby bindings for [ZeroMQ](http://zeromq.org/).

The fact is that both ffi-rzmq and rzmq are bindings for the ZeroMQ library.
ZeroMQ is an awesome library, but it provides a rather low-level API designed
for C/C++ and relatively difficult to make available to Ruby applications
through a convenient and elegant interface. Instead, ruby-czmq provides
bindings to [CZMQ](http://czmq.zeromq.org/), a library that was specifically
designed to provide a higher-level API to the ZeroMQ functions and that is
significantly more Ruby-friendly than ZeroMQ. In addition, CZMQ provides
functions, such as service discovery and cryptography, that are not present in
ZeroMQ.

By interfacing with CZMQ, instead of ZeroMQ, ruby-czmq can provide many of the
functions of ffi-rzmq and rbzmq with significantly less code.


## Installation

I have not released either ruby-czmq or ruby-czmq-ffi on RubyGems, yet. For the
moment, if you want to try ruby-czmq just place these lines:

```ruby
gem 'ruby-czmq-ffi', git: 'https://github.com/mtortonesi/ruby-czmq-ffi'
gem 'ruby-czmq', git: 'https://github.com/mtortonesi/ruby-czmq-ffi'
```

in your Gemfile and run:

    bundle install


## Examples

You can find some simple examples that demonstrate how to use the ruby-czmq api
in the [examples directory](https://github.com/mtortonesi/ruby-czmq/examples)
of this project.


## License

MIT
