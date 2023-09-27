#define _CRT_SECURE_NO_DEPRECATE  
#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

typedef struct {
	int kf;
	char base[2];
	int power;
} monomial;

monomial init(int , char*, int);

struct node {

	monomial element;
	struct node* next;
	struct node* prev;

};

typedef struct {

	struct node *begin;
	int counter;

} polynomial;

struct var
{
	char* varname;			// имя переменной
	polynomial	polynom; 	// копия полинома
	
};

polynomial init_poly();
polynomial add_monom(polynomial, monomial);
polynomial unary_poly(polynomial*);
polynomial sort(polynomial*);
polynomial remove_poly(polynomial);
polynomial sub_poly(polynomial, polynomial);
polynomial add_poly(polynomial, polynomial);
polynomial multiply(polynomial, polynomial);
polynomial search(char*);
void init_variable(char*, polynomial);
struct node* remove_node(polynomial*, struct node*);
void pprint(polynomial*);
void mprint(monomial*);


