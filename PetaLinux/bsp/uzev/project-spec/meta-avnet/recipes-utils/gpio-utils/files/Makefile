APP = gpio

LIBSOURCES=*.cpp
OUTS = *.o
NAME := gpio
MAJOR = 1.0
MINOR = 1
VERSION = $(MAJOR).$(MINOR)

all: lib$(NAME).so
lib$(NAME).so.$(VERSION): $(OUTS)
	$(CC) $(CFlAGS) $(LDFLAGS) $(OUTS) -shared -Wl,-soname,lib$(NAME).so.$(MAJOR) -o lib$(NAME).so.$(VERSION)

lib$(NAME).so: lib$(NAME).so.$(VERSION)
	rm -f lib$(NAME).so.$(MAJOR) lib$(NAME).so
	ln -s lib$(NAME).so.$(VERSION) lib$(NAME).so.$(MAJOR)
	ln -s lib$(NAME).so.$(MAJOR) lib$(NAME).so

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -c -o $(NAME).o $(LIBSOURCES)

clean:
	rm -rf *.o *.so *.so.*
