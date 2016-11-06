cocoAspell is Mac OS X interface to Aspell – A more intelligent Ispell – that is being developed by Kevin Atkinson. Here is a brief snippet of how Kevin describes Aspell on his web site:

> Aspell is an Open Source spell checker designed to eventually replace Ispell. Its main feature is that it does a much better job of coming up with possible suggestions than Ispell does. In fact recent tests shows that it even does better than Microsoft Word 97's spell checker or just about any other spell checker I have seen. It also has support for checking (La)TeX and HTML files, and run time support for other non English languages.

I have compiled Kevin's code for the Mac OS X platform. There are two major improvements over the original UNIX project:

1. cocoAspell is created as a service provider for the system-wide spelling services on Mac OS X. It means that any Mac OS X application that uses system's spell checking APIs can take advantage of Aspell's features. For example, Mail, OmniWeb, Project Builder, and TextEdit can use Aspell's ability to check spelling in different languages.

2. A preference panel named Spelling is provided with cocoAspell as an interface for dictionary selection and setup. Multiple Aspell options are available through this panel and allow the user to tune up the dictionary properties to his or her needs.
