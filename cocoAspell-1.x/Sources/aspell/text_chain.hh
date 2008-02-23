
#ifndef autil__text_chain_hh
#define autil__text_chain_hh

#include <iostream>
#include <cassert>

namespace autil {

  class TextChain {
  public: // but don't use
    struct LinkInfo {
      LinkInfo * prev;
      LinkInfo * next;
      char * begin() {
	return reinterpret_cast<char *>(this) + sizeof(LinkInfo);
      }
      char * end;
      char * storage_end;
      unsigned int size() {return end - begin();}
      unsigned int max_size() {return storage_end - begin();}
      static LinkInfo * newnode(unsigned int size);
      static unsigned int newsize(unsigned int size_needed);
      static void del(LinkInfo *);
    };
    class iterator_base {
      friend class TextChain;
      friend bool operator==(const iterator_base & rhs,
			     const iterator_base & lhs);
      friend bool operator!=(const iterator_base & rhs,
			     const iterator_base & lhs);
      friend unsigned int dist (const iterator_base & b, 
				const iterator_base & e);
    protected:
      LinkInfo   * outer;
      char       * inner;
      void inc()
      {
	++inner;
	if (inner == outer->end && outer->next != 0) {
	  outer = outer->next;
	  inner = outer->begin();
	}
      }
      void dec()
      {
	if (inner == outer->begin() && outer->prev != 0) {
	  outer = outer->prev;
	  inner = outer->end;
	}
	--inner;
      }
      iterator_base() : outer(0), inner(0) {}
      iterator_base(LinkInfo * o, char * i) : outer(o), inner(i) {}
    };
    friend bool operator==(const iterator_base & rhs,
			   const iterator_base & lhs);
    friend bool operator!=(const iterator_base & rhs,
			   const iterator_base & lhs);
    friend unsigned int dist (const iterator_base & b, 
			      const iterator_base & e);
  public:
    typedef unsigned int size_type;
    class const_iterator;
    class iterator : public iterator_base
    {
      friend class TextChain;
    public:
      iterator & operator++()  {inc(); return *this;}
      iterator & operator--()  {dec(); return *this;}
      iterator operator++(int) {iterator tmp(*this); inc(); return tmp;}
      iterator operator--(int) {iterator tmp(*this); dec(); return tmp;}
      char & operator*() const {return *inner;}
      iterator() {}
      explicit iterator(const const_iterator & i);
    private:
      iterator(LinkInfo * o, char * i) : iterator_base(o,i) {}
    };
    class const_iterator : public iterator_base
    {
      friend class TextChain;
    public:
      const_iterator & operator++()  {inc(); return *this;}
      const_iterator & operator--()  {dec(); return *this;}
      const_iterator operator++(int) {const_iterator tmp(*this); inc(); return tmp;}
      const_iterator operator--(int) {const_iterator tmp(*this); dec(); return tmp;}
      const char & operator*() const {return *inner;}
      const_iterator() {}
      const_iterator(const iterator & i) : iterator_base(i) {}
    private:
      const_iterator(LinkInfo * o, char * i) : iterator_base(o,i) {}
    };
  private:
    LinkInfo * remove(LinkInfo * n);
    void insert(LinkInfo * next, LinkInfo * to_add);

    iterator expand(LinkInfo * n, char * begin, char * end, unsigned int size);
    void shrink(LinkInfo * n, char * begin, char * end, unsigned int size);
    void remove_excess(LinkInfo * bn, LinkInfo * en, char * e);

    void reset();

    LinkInfo * first;
    LinkInfo * last;
  public:
    TextChain();
    iterator begin() {return iterator(first, first->begin());}
    iterator end()   {return iterator(last,last->end);}
    const_iterator begin() const {return const_iterator(first, first->begin());}
    const_iterator end()   const {return const_iterator(last,last->end);}
    void read(std::istream & in);
    void write(std::ostream & out);
    iterator replace(iterator begin, iterator end, const char *);
    ~TextChain() {reset();}
  };

  inline TextChain::iterator::iterator(const TextChain::const_iterator & i)
    : iterator_base(i) {}

  inline bool operator==(const TextChain::iterator_base & rhs,
			 const TextChain::iterator_base & lhs)
  {
    return rhs.inner == lhs.inner;
  }

  inline bool operator!=(const TextChain::iterator_base & rhs,
			 const TextChain::iterator_base & lhs)
  {
    return rhs.inner != lhs.inner;
  }
}


#endif
