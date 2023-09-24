%{
#include "header.h"
extern int line_counter;
%}

%union
{
	polynomial 	poly;
	monomial    mono;
	int 		num;
	char*		string;
}

/* declare tokens */

%token<string> STRING
%type<poly> polynomplus polynommulti polynompow polynomfirst
%type<mono> monom
%type<string> variable

%token<num> NUMBER
%token NUMERR
%token LBR RBR POW END PRINT EOL
%left '+' '-'
%left '*' '/'
%right UMINUS
%right POW

%start start
%%


start:
	| start END
	| start EOL
	| start programm
	;
	
programm:
	variable '=' polynomplus END
	{
		//printf("INIT variable %s\n", $1);
		init_variable($1, $3);
	}
	| PRINT variable END
	{
		polynomial tmp;
		tmp = search($2);
		if (tmp.begin == NULL) yyerror("Unknown variable");
		printf("Variable %s ", $2);
		pprint(&tmp);
	}
	| PRINT polynomplus END
	{
		printf("Polynomial expression ");
		pprint(&$2);
	}
	/* pseudo rules */
	| variable '=' polynomplus EOL 
	{	
		line_counter--;
		yyerror("Missing ';'");
	}
	| PRINT variable EOL
	{
		line_counter--;
		yyerror("Missing ';'");
	}
	| PRINT polynomplus EOL 
	{
		line_counter--;
		yyerror("Missing ';'");
	}


polynomplus:
	polynomplus '+' polynommulti
	{
		$$ = add_poly($1, $3);
	}
	| polynomplus '-' polynommulti
	{		
		$$ = sub_poly($1, $3);
	}
	| '-' polynomplus %prec UMINUS
	{
		$$ = unary_poly(&$2);
	}
	| polynommulti
	{
		$$ = $1;
	}
	/* pseudo rules */
	| polynomplus '+' '+'
	{
		yyerror("Too much '+' operators in expression");
	}
	| polynomplus '-' '-'
	{
		yyerror("Too much '-' operators in expression");
	}

polynommulti:

	polynommulti '*' polynompow
	{
		$$ = multiply($1, $3);
	}
	| polynommulti polynompow
	{
		$$ = multiply($1, $2);
	}
	| polynompow
	{
		$$ = $1;
	}
	/* pseudo rules */
	| polynommulti '*' '*'
	{
		yyerror("Too much '*' operators in expression");
	}
	| LBR '*' polynommulti
	{
		yyerror("Misspelling expression");
	}
	| polynommulti '*' RBR
	{
		yyerror("Misspelling expression");
	}
;

polynompow:

	polynompow POW polynomfirst
	{
		polynomial temp = $3;
		polynomial temp2 = $1;
		if (temp.begin->element.base == 0)
		{
			//return -1;
		}
		int pow = temp.begin->element.kf;
		if (pow == 0)
		{
			
			if (temp2.begin->element.kf == 0)
			{
				yyerror("Zero to the power of zero undefined");
			}

			$$ = init_poly();
			monomial mono = init(1, "0", 0);
			$$ = add_monom($$, mono);
		}
		else if (pow == 1)
		{
			$$ = $1;
		}
		else if (pow > 1)
		{
			$$ = $1;
			for (int i = 0; i < pow - 1; i++)
			{
				$$ = multiply($$, $1);
			}
		}
		else
		{
			yylex("Don't support powers under zero");
		}
	}
	| polynomfirst
	{
		$$ = $1;
	}
	/* pseudo rules */
	| polynompow  POW POW 
	{
		yyerror("Too much '^' operators in expression");
	}
	| polynompow POW '-'
	{
		yyerror("Don't support powers under zero");
	}
	
	
polynomfirst:
	monom
	{
		$$ = init_poly();
		$$ = add_monom($$, $1);
	}
	| variable
	{ 
		polynomial poly;
		poly = init_poly();
		monomial mono = init(1, "0", 0);
		poly = add_monom(poly, mono);
		$$ = search($1); 
		$$ = multiply($$, poly);
	}
	| LBR polynomplus RBR
	{
		$$ = $2;
	}
;

monom:

	NUMBER
	{
		$$ = init($1, "0", 0);
	}
	| STRING 
	{
		if (strlen($1) > 1) {
			yyerror("Invalid variable in polynomial expression");
		}
		$$ = init(1, $1, 1);
	}
	/* pseudorule */
	| NUMERR 
	{
		yyerror("Print numbers without zero in the beggining");
	}

;

variable: '$' STRING
		{
			int size = strlen($2);
			$$ = (char*)malloc(sizeof(char)*(size+1));
			strncpy($$, $2, size+1);
			$$[size]='\0';
		}

	

%%

int main(int argc, char **argv)
{

#ifdef __linux__ 
    yyparse();

#elif _WIN32
    FILE* inputStream = fopen("yyin.txt", "r");
    if (inputStream == NULL)
    {
        printf("Can't found input file yyin.txt\n");
        exit(-1);
}
    yyset_in(inputStream);
	yyparse();
    fclose(inputStream);
	return 0;

#endif


};


struct node* remove_node(polynomial *p, struct node *n) {

	struct node* res = n;

	if (p->begin == n)
	{
		if (n->next == NULL)
		{
			return NULL;
		}

		n->next->prev = NULL;
		res = n->next;
		p->begin = res;
		return res;
	}

	if (n->next == NULL)
	{
		n->prev->next = NULL;
		res = n->prev;
		return res;
	}

	n->next->prev = n->prev;
	n->prev->next = n->next;
	res = n->prev;
	return res;

}

polynomial remove_poly(polynomial p)
{
	polynomial result = init_poly();
	monomial tmp_monom;
	struct node* tmp1 = p.begin;
	struct node* tmp2;

	while (tmp1 != NULL)
	{
		tmp_monom = tmp1->element;
		tmp2 = p.begin;

		while (tmp2 != NULL)
		{
			if (tmp1->element.power == tmp2->element.power && tmp1 != tmp2)
			{
				tmp_monom.kf += tmp2->element.kf;
				tmp2 = remove_node(&p, tmp2);
			}

			tmp2 = tmp2->next;
		}

		tmp1 = remove_node(&p, tmp1);
		result = add_monom(result, tmp_monom);
	}

	return result;
}



polynomial add_poly(polynomial p1, polynomial p2) {

	for (struct node* i = p1.begin; i != NULL; i = i->next) {
		char ibase = i->element.base[0];
		for (struct node* j = p2.begin; j != NULL; j = j->next) {
			char jbase = j->element.base[0];
			if (ibase != jbase && ibase!='0' && jbase!='0') yyerror("Sorry! Can't perform multivariable polynomial expressions =(");
			
		}
	}
	
	
	polynomial res = p1;
	struct node* tmp = p2.begin;

	res = add_monom(res, tmp->element);
	while (tmp->next != NULL) {
		tmp = tmp->next;
		res = add_monom(res, tmp->element);
	}
	// !!!!!
	return res = remove_poly(res);
}


polynomial sub_poly(polynomial p1, polynomial p2) {

	return add_poly(p1, unary_poly(&p2));
}


polynomial add_monom(polynomial p, monomial m) {

	polynomial res;
	struct node* tmp;
	res = p;
	
	// идем от начала полинома
	tmp = res.begin;

	// если полином пустой, формируем его, добавляя моном 
	if (res.counter == 0)
	{
		tmp->element = m;
		res.counter++;
		return res;
	}

	// иначе идем в конец полинома 
	while (tmp->next != NULL)
	{
		tmp = tmp->next;
	}
	
	// цепляем наш моном	
	tmp->next = (struct node*)malloc(sizeof(struct node));
	tmp->next->prev = tmp;
	tmp->next->next = NULL;
	tmp = tmp->next;
	tmp->element = m;
	res.counter++;
	return res;

};


polynomial multiply(polynomial p1, polynomial p2) {
	
	polynomial res = init_poly();
	
	for (struct node *i = p1.begin; i != NULL; i = i->next)
	{
		for (struct node *j = p2.begin; j != NULL; j = j->next)
		{
			monomial monom = i->element;
			monom.kf *= j->element.kf;
						
			// оба не числа
			if (monom.base[0] != '0' && (monom.base[0] == j->element.base[0]))
			{
				monom.power += j->element.power;
			}
			else if (monom.base[0] == '0' && j->element.base[0] != '0')
			{
				monom.base[0] = j->element.base[0];
				monom.power += j->element.power;
			}
			else if (monom.base[0] != '0' && j->element.base[0] !='0' && (monom.base[0]!=j->element.base[0]))
			{
				yyerror("Sorry! Can't perform multivariable polynomial expressions =(");
			}

			if (monom.kf == 0)
			{
				
				monom.base[0] = '0';
				monom.power = 0;
			}

			res = add_monom(res, monom);
		}
	}

	res = remove_poly(res);
	return res;

}

polynomial unary_poly(polynomial *p) {
	
	struct node* tmp = p->begin;

	while (tmp != NULL)
	{
		tmp->element.kf *= (-1);
		tmp = tmp->next;
	}

	return *p;
}

polynomial init_poly() {

	polynomial tmp;
	tmp.begin = (struct node *)malloc(sizeof(struct node));
	tmp.begin->prev = NULL;
	tmp.begin->next = NULL;
	tmp.counter = 0;
	return tmp;
};

monomial init(int kf, char* base, int power) {
	
	monomial tmp;
	tmp.kf = kf;
	tmp.base[0] = base[0];
	tmp.base[1] = '\0';
	tmp.power = power;
	return tmp;

};

void mprint(monomial* m) {

	if (m->base[0] == '0')
	{
		printf("%d", m->kf);
	}
	else
	{
		if (abs(m->kf) == 1)
		{
			if (m->kf == -1)
			{
				printf("-");
			}
			if (m->power == 1)
			{
				printf("%s", m->base);
			}
			else
			{
				printf("%s^%d", m->base, m->power);
			}
		}
		else
		{
			if (m->power == 1)
			{
				printf("%d%s", m->kf, m->base);
			}
			else
			{
				if (m->kf == 1)
				{
					printf("%s^%d", m->base, m->power);
				}
				else
				{
					printf("%d%s^%d", m->kf, m->base, m->power);
				}
			}
		}
	}
	
}

struct var* global_var_list;
int var_counter = 0;


polynomial search(char* name) {
	
	for (int i = 0; i < var_counter;i++) if (!strcmp(name, global_var_list[i].varname)) return global_var_list[i].polynom;
	yyerror("Unknown variable");
}

int check_in_global_list(char* name) {
	
	for (int i = 0; i < var_counter; i++) if (!strcmp(name, global_var_list[i].varname)) return 1;
    return 0;
	
}
void replace(char* name, polynomial polynom) {
	
	for (int i = 0; i < var_counter;i++) {
		if (!strcmp(name, global_var_list[i].varname)) {
			global_var_list[i].polynom = polynom;
			return;
		}
	}
}

void init_variable(char* name, polynomial polynom) {
	
	struct var variable;
	int size = strlen(name);
	variable.varname = (char*)malloc(sizeof(char)*(size+1));
	strncpy(variable.varname, name, size);
	variable.varname[size]='\0';
	variable.polynom = polynom;
	if (var_counter == 0) global_var_list = (struct var*)malloc(sizeof(struct var)*(var_counter+1));
	else {
		if(!check_in_global_list(name)) global_var_list = (struct var*)realloc(global_var_list, sizeof(struct var)*(var_counter+1));
		else {
			printf("WARNING in line %d: Variable '$%s' reinitialization\n", line_counter, name);
			replace(name, polynom);
			return;
		}
	}
	global_var_list[var_counter] = variable;
	var_counter++;
	
}
	

void pprint(polynomial* p) {

	struct node *tmp = p->begin;
	printf("= ");
	while (tmp->element.kf == 0 && tmp->next != NULL)
	{
		tmp = tmp->next;
		continue;
	}

	mprint(&(tmp->element));
	tmp = tmp->next;
	while (tmp != NULL)
	{
		if (tmp->element.kf == 0)
		{
			tmp = tmp->next;
			continue;
		}
		
		//!!!!!!!!!!
		if (tmp->element.kf > 0) printf("+");
		mprint(&(tmp->element));
		tmp = tmp->next;
	}
	printf("\n");

}

int yyerror(char *msg)
{
    fprintf(stderr, "ERROR IN LINE %d: %s\n", line_counter+1,  msg);
	exit(-1);
	
}