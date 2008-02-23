
#include "text_chain.hh"
#include <string>

namespace autil {

  using namespace std;

  TextChain::LinkInfo * TextChain::LinkInfo::newnode(unsigned int size) 
  {
    LinkInfo * li = reinterpret_cast<LinkInfo *>(new char[size]);
    li->end         = li->begin();
    li->storage_end = li->begin() + size;
    li->prev = 0;
    li->next = 0;
    return li;
  }

  void TextChain::LinkInfo::del(LinkInfo * node) {
    char * data = reinterpret_cast<char *>(node);
    delete[] data;
  }

  unsigned int TextChain::LinkInfo::newsize(unsigned int size_needed) {
    size_needed += sizeof(LinkInfo) + 1024 + 256;
    size_needed = (size_needed / 1024) * 1024;
    return size_needed;
  }

  unsigned int dist (const TextChain::iterator_base & b, 
		     const TextChain::iterator_base & e)
  {
    TextChain::LinkInfo * n = b.outer;
    unsigned int d = 0;
    while (true) {
      const char * b0 = (b.outer == n) ? b.inner : n->begin();
      const char * e0 = (n == e.outer) ? e.inner : n->end;
      d += static_cast<unsigned int>(e0 - b0);
      if (n == e.outer) break;
      n = n->next;
    } 
    return d;
  }

  TextChain::TextChain()
    : first(0), last(0)
  {
  }

  void TextChain::read(istream & in) 
  {
    reset();
    first = LinkInfo::newnode(1024*4);
    last  = first;
    while (true) {
      in.read(last->begin(), last->max_size() - 256);
      last->end += in.gcount();
      if (in.eof()) break;
      LinkInfo * n = LinkInfo::newnode(1024*4);
      n->prev = last;
      last->next = n;
      last = last->next;
    }
  }

  void TextChain::write(ostream & out) 
  {
    LinkInfo * n = first;
    while (out && n != 0) {
      out.write(n->begin(), n->size());
      n = n->next;
    }
  }

  TextChain::iterator TextChain::expand(LinkInfo * node, 
					char * begin, char * end, 
					unsigned int size)
  {
    if (node->storage_end - node->end >= static_cast<int>(size)) {
      memmove(end + size, end, node->end - end);
      node->end += size;
      return iterator(node,begin);
    } else {
      unsigned int newsize = LinkInfo::newsize(node->size() + size);
      unsigned int begin_offset = begin - node->begin();
      LinkInfo * newnode = LinkInfo::newnode(newsize);
      memcpy(newnode->begin(), node->begin(), begin_offset);
      memcpy(newnode->begin() + (end - node->begin()), end, node->end - end);
      newnode->end = newnode->begin() + (node->end - node->begin()) + size;
      LinkInfo * next = remove(node);
      insert(next, newnode);
      return iterator(newnode,newnode->begin() + begin_offset);
    }
  }

  void TextChain::shrink(LinkInfo * node, 
			 char * begin, char * end, 
			 unsigned int size)
  {
    assert(end-begin >= static_cast<int>(size));
    memmove(end - size, end, node->end - end);
    node->end -= size;
  }

  void TextChain::remove_excess(LinkInfo * bn, LinkInfo * en, char * e)
  {
    while (bn != en) {
      bn = remove(bn);
    }
    if (e == en->end) {
      remove(bn);
    } else if (en->begin() != e) {
      memmove(en->begin(), e, en->end - e);
      en->end -= e - en->begin();
    }
  }

  void TextChain::reset() 
  {
    while (first != 0) {
      LinkInfo * next = first->next;
      LinkInfo::del(first);
      first = next;
    }
    last = 0;
  }

  TextChain::LinkInfo * TextChain::remove(LinkInfo * n) 
  {
    if (n->prev == 0) {
      first = n->next;
    } else {
      n->prev->next = n->next;
    }

    if (n->next == 0) {
      last = n->prev;
    } else {
      n->next->prev = n->prev;
    }

    LinkInfo * next = n->next;
    LinkInfo::del(n);
    return next;
  }

  void TextChain::insert(LinkInfo * next, LinkInfo * to_add) 
  {
    if (first == 0) {            // first element

      first = to_add;
      last  = to_add;

    } else if (next == 0) {      // insert at end

      to_add->prev = last;
      last->next = to_add;
      last = to_add;

    } else if (next->prev == 0) { // insert at beginning

      to_add->next = next;
      first->prev = to_add;
      first = to_add;

    } else {                     // insert in middle

      to_add->next = next;
      to_add->prev = next->prev;
      next->prev = to_add;
      next->prev->next = to_add;

    }
  }
  
  TextChain::iterator TextChain::replace(iterator b, iterator e, 
					 const char * str) 
  {
    if (b.outer != e.outer) {
      remove_excess(b.outer->next, e.outer, e.inner);
      
      e.outer = b.outer;
      e.inner = b.outer->end;
    }

    unsigned int org_dif = e.inner - b.inner;
    unsigned int new_dif = strlen(str);
    
    if (org_dif < new_dif)
      b = expand(b.outer, b.inner, e.inner, new_dif - org_dif);
    else if (org_dif > new_dif)
      shrink(b.outer, b.inner, e.inner,  org_dif - new_dif);

    memcpy(b.inner, str, new_dif);
    return b;
  }
}
