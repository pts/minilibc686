/* based on dietlibc-0.34/lib/bsearch.c */

#define __likely(x) (x)
typedef unsigned size_t;

void *bsearch(const void *key, const void *base, size_t nmemb, size_t size, int (*compar)(const void* , const void* )) {
  size_t m;
  while (__likely(nmemb)) {
    int tmp;
    void *p;
    m=nmemb/2;
    p=(void *) (((const char *) base) + (m * size));
    if ((tmp=(*compar)(key,p))<0) {
      nmemb=m;
    } else if (tmp>0) {
      base=(const char*)p+size;
      nmemb-=m+1;
    } else
      return p;
  }
  return 0;
}
