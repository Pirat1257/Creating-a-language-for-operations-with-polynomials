%{
#include <stdio.h>
#include <stdlib.h>
#define YYDEBUG 1
FILE* yyin;
int find_error = 0;
int global_find_error = 0;
int line = 1;
int show_line = 0;
char dif_mes[41] = "Two different variables c and c are used";
char bad_fir[53] = "The operation symbol c cannot be the first character";
char inc_var[52] = "Incorrect variable-polynomial $c was used. Use $A-Z";

/*---------------Структура описывающая каждое слагаемое---------------*/
struct letters
{
	int what; // 1 - num*sym^(pow) это переменная, 2 - num^(pow) это число;
	int number; // Умножение на число или просто число.
	int mul; // В случае, когда это num^(pow): pow != NULL.
	struct letters* pow; // Возведение в степень. Если ее нет, то NULL.
	char symbol; // Символ переменной.
	char operation; // +-
	struct letters* pnext; // Указатель на следующий элемент.
	struct letters* pprev; // Указатель на предыдущий элемент.
	char op_check; // Для проверки ошибок нескольких знаков подряд
	char br_check; // Для проверки ошибок отсутствия знаков между скобками
};

/*---------------Структура описывающая все полиномы, используется при выводе ответа---------------*/
struct result
{
	struct letters* point;
	struct result* pnext;
};
struct result* res_head = NULL;

/*---------------Структура описывающая глобальные переменные---------------*/
struct glob_var
{
	char symbol;
	struct letters* var;
	struct glob_var* pnext;
};
struct glob_var* var_head = NULL;

/*---------------Равенство полиномов---------------*/
int compare_polynomial(struct letters* A, struct letters* B) // 0 - не равны, 1 - равны
{
	// Эти три условия необходимы для случая num*sym^(pow) + num*sym^(pow), если pow будет NULL
	if (A == NULL && B == NULL)
		return 1;
	else if (A != NULL && B == NULL)
		return 0;
	else if (A == NULL && B != NULL)
		return 0;
	while (1)
	{
		// Сравниваем, чтобы все совпало
		if (A->number == B->number &&
			compare_polynomial(A->pow, B->pow) &&
			A->symbol == B->symbol &&
			A->what == B->what &&
			A->operation == B->operation)
		{
			// Если прошло проверку, рассматриваем переход на след. узел
			if (A->pnext == NULL && B->pnext == NULL)
				return 1;
			else if (A->pnext != NULL && B->pnext != NULL)
			{
				A = A->pnext;
				B = B->pnext;
			}
			else return 0; // Если у одного переход возможен, а у другого нет, то это говорит о разной длине
		}
		else return 0;
	}
}

/*---------------Сравнение полиномов---------------*/
int more_or_less(struct letters* A, struct letters* B) // 0: A == B; 1: А > B; 2: A < B
{
	if (A != NULL && B == NULL)
		return 1;
	else if (A == NULL && B != NULL)
		return 2;
	else if (A == NULL && B == NULL)
		return 0;
	while (1)
	{
		// Пытаемся найти разницу
		if (A->what == 2 && B->what == 2) // num ? num
		{
			if (A->pow == NULL && B->pow == NULL) // num ? num
			{
				if (A->operation == B->operation) // [+-]num ? [+-]num
				{
					if (A->number > B->number)
					{
						if (A->operation == '-' && B->operation == '-')
							return 2;
						else if (A->operation == '-' && B->operation == '+')
							return 2;
						return 1;
					}
					else if (A->number < B->number)
					{
						if (A->operation == '-' && B->operation == '-')
							return 1;
						else if (A->operation == '+' && B->operation == '-')
							return 1;
						return 2;
					}
				}
				else if (A->operation == '+') // num ? -num
					return 1;
				else if (B->operation == '+') // -num ? num
					return 2;
			}
			else if (A->pow == NULL && B->pow != NULL) // num ? num^pow
			{
				return 2;
			}
			else if (A->pow != NULL && B->pow == NULL) // num^pow ? num
			{
				return 1;
			}
			else if (A->pow != NULL && B->pow != NULL) // num^pow ? num^pow
			{
				int res = more_or_less(A->pow, B->pow);
				if (res == 1)
					return 1;
				else if (res == 2)
					return 2;
			}
		}
		else if (A->what == 2 && B->what == 1) // num ? num*sym^(pow)
		{
			return 2;
		}
		else if (A->what == 1 && B->what == 2) // num*sym^(pow) ? num
		{
			return 1;
		}
		else if (A->what == 1 && B->what == 1) // num*sym^(pow) ? num*sym^(pow)
		{
			if (A->pow == NULL && B->pow == NULL) // num*sym ? num*sym
			{
				if (A->operation == B->operation) // [+-]num*sym ? [+-]num*sym
				{
					if (A->pnext != NULL && B->pnext != NULL) // num*sym+... ? num*sym+...
						return more_or_less(A->pnext, B->pnext);
					else if (A->pnext == NULL && B->pnext == NULL) // num*sym ? num*sym
						return 0;
					else if (A->pnext != NULL && B->pnext == NULL) // num*sym+... ? num*sym
						return 1;
					else if (A->pnext == NULL && B->pnext != NULL) // num*sym ? num*sym+...
						return 2;

				}
				else if (A->operation == '+') // num*sym ? -num*sym
					return 1;
				else if (B->operation == '+') // -num*sym ? num*sym
					return 2;
			}
			else if (A->pow != NULL && B->pow == NULL) // num*sym^(pow) ? num*sym
			{
				return 1;
			}
			else if (A->pow == NULL && B->pow != NULL) // num*sym ? num*sym^(pow)
			{
				return 2;
			}
			else if (A->pow != NULL && B->pow != NULL) // num*sym^(pow) ? num*sym^(pow)
			{
				int res = more_or_less(A->pow, B->pow);
				if (res == 1)
					return 1;
				else if (res == 2)
					return 2;
			}
		}
		// Если оказались здесь, значит не нашли разницы
		if (A->pnext != NULL && B->pnext != NULL) // Если есть еще что рассмотерть, рассматриваем
		{
			A = A->pnext;
			B = B->pnext;
		}
		else if (A->pnext == NULL && B->pnext != NULL) // Если А кончился, а В нет, вернем В
			return 2;
		else if (A->pnext != NULL && B->pnext == NULL) // Аналогично с А
			return 1;
		else if (A->pnext == NULL && B->pnext == NULL) // Оба кончились и оба одинаковы
			return 0;
	}
}

/*---------------Создание узла---------------*/
struct letters* create_point(int what, int number, struct letters* pow, char symbol, char operation)
{
	struct letters* new_one = (struct letters*)malloc(sizeof(struct letters));
	new_one->what = what;
	new_one->number = number;
	new_one->pow = pow;
	new_one->symbol = symbol;
	new_one->operation = operation;
	new_one->mul = 1;
	new_one->pnext = NULL;
	new_one->pprev = NULL;
	new_one->op_check = '0';
	new_one->br_check = '0';
	return new_one;
}

/*---------------Получение предыдущего узла---------------*/
struct letters* get_prev(struct letters* head, struct letters* target)
{
	if (head == target)
		return NULL;
	struct letters* dummy = head;
	while (1)
	{
		if (dummy->pnext == target)
			return dummy;
		else if (dummy->pnext != NULL)
			dummy = dummy->pnext;
		else
			return NULL;
	}
}

/*---------------Удаление узла---------------*/
struct letters* del(struct letters* head, struct letters* target)
{
	struct letters* dummy = head;
	// Ищем узел
	while (dummy != target)
	{
		dummy = dummy->pnext;
	}
	// Нашли узел, меняем указатели
	if (dummy->pprev != NULL && dummy->pnext != NULL) // <-x->
	{
		dummy->pprev->pnext = dummy->pnext;
		dummy->pnext->pprev = dummy->pprev;
	}
	else if (dummy->pprev == NULL && dummy->pnext != NULL) // x->
	{
		dummy->pnext->pprev = NULL;
		head = dummy->pnext;
	}
	else if (dummy->pprev != NULL && dummy->pnext == NULL) // <-x
	{
		dummy->pprev->pnext = NULL;
	}
	else if (dummy->pprev == NULL && dummy->pnext == NULL) // x
	{
		head = NULL;
	}
	free(target);
	return head;
}

/*---------------Добавление узла---------------*/
struct letters* push(struct letters* head, struct letters* before, struct letters* after, struct letters* target)
{
	struct letters* dummy = create_point(target->what, target->number, target->pow, target->symbol, target->operation);
	if (before == NULL && after == NULL)
		return dummy;
	else if (before == NULL && after != NULL)
	{
		after->pprev = dummy;
		dummy->pnext = after;
		return dummy;
	}
	else if (before != NULL && after == NULL)
	{
		before->pnext = dummy;
		dummy->pprev = before;
		return head;
	}
	else if (before != NULL && after != NULL)
	{
		before->pnext = dummy;
		dummy->pprev = before;
		after->pprev = dummy;
		dummy->pnext = after;
		return head;
	}
}

/*---------------Сложение и вычитание полиномов---------------*/
struct letters* sum_diff(struct letters* A, struct letters* B, char operation);

/*---------------Копирование полинома---------------*/
struct letters* copy_pol(struct letters* A, struct letters* before)
{
	if (A == NULL)
		return NULL;
	struct letters* new_one = create_point(A->what, A->number, copy_pol(A->pow, NULL), A->symbol, A->operation);
	new_one->pprev = before;
	new_one->mul = A->mul;
	if (A->pnext != NULL)
	{
		A = A->pnext;
		new_one->pnext = copy_pol(A, new_one);
	}
	return new_one;
}

/*---------------Добавление узла в полином---------------*/
struct letters* find_place(struct letters* head, struct letters* new_one)
{
	struct letters* dummy = head;
	if (head == NULL) // Если справа получился 0, и к нему добавляют что то
	{
		struct letters* new_head = create_point(new_one->what, new_one->number, new_one->pow, new_one->symbol, new_one->operation);
		new_head->mul = new_one->mul;
		return new_head;
	}
	while (1)
	{
		if (new_one->what == 1) // num*sym^(pow)
		{
			if ((dummy->what == 1) && more_or_less(dummy, new_one) == 2) // Новый оказался больше, вставляем перед старым
			{
				return push(head, dummy->pprev, dummy, create_point(new_one->what, new_one->number, copy_pol(new_one->pow, NULL), new_one->symbol, new_one->operation) /*new_one*/);
			}
			else if (dummy->what == 2)
			{
				return push(head, dummy->pprev, dummy, create_point(new_one->what, new_one->number, copy_pol(new_one->pow, NULL), new_one->symbol, new_one->operation) /*new_one*/);
			}
			else if ((dummy->what == 1) && more_or_less(dummy->pow, new_one->pow) == 0)
			{
				return sum_diff(head, new_one, '+');
			}
		}
		else if (new_one->what == 2)
		{
			while (1)
			{
				if (dummy->pnext == NULL)
					break;
				else dummy = dummy->pnext;
			}
			return push(head, dummy, NULL, create_point(new_one->what, new_one->number, copy_pol(new_one->pow, NULL), new_one->symbol, new_one->operation) /*new_one*/);
		}
		// Если не произошел выбор, рассматриваем дальше, 
		if (dummy->pnext != NULL)
			dummy = dummy->pnext;
		else // Если выбора не было, и дошли до конца, добавляем в конец
		{
			return push(head, dummy, NULL, create_point(new_one->what, new_one->number, copy_pol(new_one->pow, NULL), new_one->symbol, new_one->operation) /*new_one*/);
		}
	}
}

/*---------------Сложение и вычитание полиномов---------------*/
struct letters* sum_diff(struct letters* A, struct letters* B, char operation)
{
	struct letters* dummy_B = B;
	struct letters* dummy_A = copy_pol(A, NULL);
	A = dummy_A;

	int find = 0;
	if (operation == '+') // Если сумма
	{
		while (1) // Цикл для В
		{
			dummy_A = A;
			while (1) // Цикл для А
			{
				if (dummy_A->what == 1 && dummy_B->what == 1) // Рассматривается случай num*sym^(pow) + num*sym^(pow), складываются если значения polynomial равны
				{
					if (compare_polynomial(dummy_A->pow, dummy_B->pow) == 1) //Степени pow одинаковы, можем складывать
					{
						// Производим рассмотрение знаков
						if (dummy_A->operation == '+' && dummy_B->operation == '+') // ...(+num*sym^(pow))...+...(+num*sym^(pow))
							dummy_A->number += dummy_B->number;
						else if (dummy_A->operation == '+' && dummy_B->operation == '-') // ...(+num*sym^(pow))...+...(-num*sym^(pow))
						{
							dummy_A->number -= dummy_B->number;
							if (dummy_A->number > 0)
								dummy_A->operation = '+';
							else if (dummy_A->number == 0)
							{
								if (A->pnext != NULL)
								{
									A = del(A, dummy_A);
								}
								else dummy_A->operation = '+';
							}
							else
							{
								dummy_A->number = dummy_A->number * (-1);
								dummy_A->operation = '-';
							}
						}
						else if (dummy_A->operation == '-' && dummy_B->operation == '+') // ...(-num*sym^(pow))...+...(+num*sym^(pow))
						{
							dummy_A->number = dummy_A->number * (-1) + dummy_B->number;
							if (dummy_A->number > 0)
								dummy_A->operation = '+';
							else if (dummy_A->number == 0)
							{
								if (A->pnext != NULL)
								{
									A = del(A, dummy_A);
								}
								else dummy_A->operation = '+';
							}
							else
							{
								dummy_A->number = dummy_A->number * (-1);
								dummy_A->operation = '-';
							}
						}
						else if (dummy_A->operation == '-' && dummy_B->operation == '-') // ...(-num*sym^(pow))...+...(-num*sym^(pow))
							dummy_A->number += dummy_B->number;

						// Производим удаление обработанного узла в B
						find = 1;
						break;
					}
				}
				else if (dummy_A->what == 2 && dummy_B->what == 2) // Рассматривается случай num^(pow) + num^(pow), складывается, если pow равны NULL или оба равны
				{
					if (dummy_A->pow == NULL && dummy_B->pow == NULL) // num + num
					{
						// Производим рассмотрение знаков
						if (dummy_A->operation == '+' && dummy_B->operation == '+') // ...(+num)...+...(+num)
							dummy_A->number += dummy_B->number;
						else if (dummy_A->operation == '+' && dummy_B->operation == '-') // ...(+num)...+...(-num)
						{
							dummy_A->number -= dummy_B->number;
							if (dummy_A->number > 0)
								dummy_A->operation = '+';
							else if (dummy_A->number == 0)
							{
								if (A->pnext != NULL)
								{
									A = del(A, dummy_A);
								}
								else dummy_A->operation = '+';
							}
							else
							{
								dummy_A->number = dummy_A->number * (-1);
								dummy_A->operation = '-';
							}
						}
						else if (dummy_A->operation == '-' && dummy_B->operation == '+') // ...(-num)...+...(+num)
						{
							dummy_A->number = dummy_A->number * (-1) + dummy_B->number;
							if (dummy_A->number > 0)
								dummy_A->operation = '+';
							else if (dummy_A->number == 0)
							{
								if (A->pnext != NULL)
								{
									A = del(A, dummy_A);
								}
								else dummy_A->operation = '+';
							}
							else
							{
								dummy_A->number = dummy_A->number * (-1);
								dummy_A->operation = '-';
							}
						}
						else if (dummy_A->operation == '-' && dummy_B->operation == '-') // ...(-num)...+...(-num)
							dummy_A->number += dummy_B->number;
						find = 1;
						break;
					}
					else if (dummy_A->pow != NULL && dummy_B->pow != NULL) // num^(pow) + num^(pow)
					{
						if (compare_polynomial(dummy_A->pow, dummy_B->pow) == 1) // Если pow совпали
						{
							if (dummy_A->operation == '+' && dummy_B->operation == '+') // ...(+mul*num^(pow))...+...(+mul*num^(pow))
								dummy_A->mul += dummy_B->mul;
							else if (dummy_A->operation == '+' && dummy_B->operation == '-') // ...(+mul*num^(pow))...+...(-mul*num^(pow))
							{
								dummy_A->mul -= dummy_B->mul;
								if (dummy_A->mul > 0)
									dummy_A->operation = '+';
								else if (dummy_A->mul == 0)
								{
									if (A->pnext != NULL)
									{
										A = del(A, dummy_A);
									}
									else dummy_A->operation = '+';
								}
								else
								{
									dummy_A->mul = dummy_A->mul * (-1);
									dummy_A->operation = '-';
								}
							}
							else if (dummy_A->operation == '-' && dummy_B->operation == '+') // ...(-mul*num^(pow))...+...(+mul*num^(pow))
							{
								dummy_A->mul = dummy_A->mul * (-1) + dummy_B->mul;
								if (dummy_A->mul > 0)
									dummy_A->operation = '+';
								else if (dummy_A->mul == 0)
								{
									if (A->pnext != NULL)
									{
										A = del(A, dummy_A);
									}
									else dummy_A->operation = '+';
								}
								else
								{
									dummy_A->mul = dummy_A->mul * (-1);
									dummy_A->operation = '-';
								}
							}
							else if (dummy_A->operation == '-' && dummy_B->operation == '-') // ...(-mul*num^(pow))...+...(-mul*num^(pow))
								dummy_A->mul += dummy_B->mul;
							find = 1;
							break;
						}
					}
				}
				if (A == NULL) // Получили справа 0
					break;
				else if (dummy_A->pnext == NULL)
					break;
				else
					dummy_A = dummy_A->pnext;
			}

			// Если ни одного совпадения не было обнаружено, производим добавление узла в А и его удаление в В
			if (find == 0)
			{
				if (operation == '-')
				{
					if (dummy_B->operation == '-')
						dummy_B->operation = '+';
					else dummy_B->operation = '-';
				}
				A = find_place(A,  dummy_B);
			}
			find = 0;
			if (dummy_B->pnext == NULL) // Если разобрали всю правую часть, то на выход
				return A;
			else dummy_B = dummy_B->pnext;
		}
	}
	else // Если разность
	{
		while (1) // Цикл для В
		{
			dummy_A = A;
			while (1) // Цикл для А
			{
				if (dummy_A->what == 1 && dummy_B->what == 1) // Рассматривается случай num*sym^(pow) - num*sym^(pow), складываются если значения polynomial равны
				{
					if (compare_polynomial(dummy_A->pow, dummy_B->pow) == 1) //Степени pow одинаковы, можем складывать
					{
						// Производим рассмотрение знаков
						if (dummy_A->operation == '+' && dummy_B->operation == '+') // ...(+num*sym^(pow))...-...(+num*sym^(pow))
						{
							dummy_A->number -= dummy_B->number;
							if (dummy_A->number < 0)
							{
								dummy_A->number *= (-1);
								dummy_A->operation = '-';
							}
							else if (dummy_A->number == 0)
							{
								if (A->pnext != NULL)
								{
									A = del(A, dummy_A);
								}
								else dummy_A->operation = '+';
							}
						}
						else if (dummy_A->operation == '+' && dummy_B->operation == '-') // ...(+num*sym^(pow))...-...(-num*sym^(pow))
						{
							dummy_A->number += dummy_B->number;
						}
						else if (dummy_A->operation == '-' && dummy_B->operation == '+') // ...(-num*sym^(pow))...-...(+num*sym^(pow))
						{
							dummy_A->number += dummy_B->number;
						}
						else if (dummy_A->operation == '-' && dummy_B->operation == '-') // ...(-num*sym^(pow))...-...(-num*sym^(pow))
						{
							dummy_A->number -= dummy_B->number;
							if (dummy_A->number < 0)
							{
								dummy_A->number *= (-1);
								dummy_A->operation = '+';
							}
							else if (dummy_A->number == 0)
							{
								if (A->pnext != NULL)
								{
									A = del(A, dummy_A);
								}
								else dummy_A->operation = '+';
							}
						}
						find = 1;
						break;
					}
				}
				else if (dummy_A->what == 2 && dummy_B->what == 2) // Рассматривается случай num^(pow) - num^(pow), складывается, если pow равны NULL или оба равны
				{
					if (dummy_A->pow == NULL && dummy_B->pow == NULL) // num - num
					{
						// Производим рассмотрение знаков
						if (dummy_A->operation == '+' && dummy_B->operation == '+') // ...(+num)...-...(+num)
						{
							dummy_A->number -= dummy_B->number;
							if (dummy_A->number > 0)
								dummy_A->operation = '+';
							else if (dummy_A->number == 0)
							{
								if (A->pnext != NULL)
								{
									A = del(A, dummy_A);
								}
								else dummy_A->operation = '+';
							}
							else
							{
								dummy_A->number = dummy_A->number * (-1);
								dummy_A->operation = '-';
							}
						}
						else if (dummy_A->operation == '+' && dummy_B->operation == '-') // ...(+num)...-...(-num)
						{
							dummy_A->number += dummy_B->number;
						}
						else if (dummy_A->operation == '-' && dummy_B->operation == '+') // ...(-num)...-...(+num)
						{
							dummy_A->number += dummy_B->number;
						}
						else if (dummy_A->operation == '-' && dummy_B->operation == '-') // ...(-num)...-...(-num)
						{
							dummy_A->number -= dummy_B->number;
							if (dummy_A->number < 0)
							{
								dummy_A->number *= (-1);
								dummy_A->operation = '+';
							}
							else if (dummy_A->number == 0)
							{
								if (A->pnext != NULL)
								{
									A = del(A, dummy_A);
								}
								else dummy_A->operation = '+';
							}
						}
						find = 1;
						break;
					}
					else if (dummy_A->pow != NULL && dummy_B->pow != NULL) // num^(pow) + num^(pow)
					{
						if (compare_polynomial(dummy_A->pow, dummy_B->pow) == 1) // Если pow совпали
						{
							if (dummy_A->operation == '+' && dummy_B->operation == '+') // ...(+mul*num^(pow))...-...(+mul*num^(pow))
							{
								dummy_A->mul -= dummy_B->mul;
								if (dummy_A->mul > 0)
									dummy_A->operation = '+';
								else if (dummy_A->mul == 0)
								{
									if (A->pnext != NULL)
									{
										A = del(A, dummy_A);
									}
									else dummy_A->operation = '+';
								}
								else
								{
									dummy_A->mul = dummy_A->mul * (-1);
									dummy_A->operation = '-';
								}
							}
							else if (dummy_A->operation == '+' && dummy_B->operation == '-') // ...(+mul*num^(pow))...-...(-mul*num^(pow))
							{
								dummy_A->mul += dummy_B->mul;
							}
							else if (dummy_A->operation == '-' && dummy_B->operation == '+') // ...(-mul*num^(pow))...-...(+mul*num^(pow))
							{
								dummy_A->mul += dummy_B->mul;
							}
							else if (dummy_A->operation == '-' && dummy_B->operation == '-') // ...(-mul*num^(pow))...-...(-mul*num^(pow))
							{
								dummy_A->mul -= dummy_B->mul;
								if (dummy_A->mul > 0)
									dummy_A->operation = '-';
								else if (dummy_A->mul == 0)
								{
									if (A->pnext != NULL)
									{
										A = del(A, dummy_A);
									}
									else dummy_A->operation = '+';
								}
								else
								{
									dummy_A->mul = dummy_A->mul * (-1);
									dummy_A->operation = '+';
								}
							}
							find = 1;
							break;
						}
					}
				}
				if (A == NULL) // Это могло произойти если получился 0
					break;
				else if (dummy_A->pnext == NULL)
					break;
				else
					dummy_A = dummy_A->pnext;
			}
			// Если ни одного совпадения не было обнаружено, производим добавление узла в А
			if (find == 0)
			{
				if (operation == '-')
				{
					if (dummy_B->operation == '-')
						dummy_B->operation = '+';
					else dummy_B->operation = '-';
				}
				A = find_place(A, dummy_B);
			}
			find = 0;
			if (dummy_B->pnext == NULL) // Если разобрали всю правую часть, то на выход
				return A;
			else dummy_B = dummy_B->pnext;
		}
	}
}

/*---------------Умножение полиномов---------------*/
struct letters* multiplication(struct letters* A, struct letters* B)
{
	struct letters* dummy_B = B;
	struct letters* dummy_A = A;
	struct letters* C = NULL; // Сюда записывается результат
	struct letters* dummy_C = NULL;
	struct letters* one = create_point(2, 1, NULL, '0', '+');

	while (1) // Цикл для B
	{
		dummy_A = A;
		while (1) // Цикл для A
		{
			if (dummy_A->what == 1 && dummy_B->what == 1) // num*sym^(pow) * num*sym^(pow)
			{
				struct letters* new_pow = NULL;
				if (dummy_A->pow != NULL && dummy_B->pow == NULL) // num*sym^(pow) * num*sym
					new_pow = sum_diff(copy_pol(dummy_A->pow, NULL),
						create_point(2, 1, NULL, '0', '+'), '+');
				else if (dummy_A->pow == NULL && dummy_B->pow != NULL) // num*sym * num*sym^(pow)
					new_pow = sum_diff(copy_pol(dummy_B->pow, NULL),
						create_point(2, 1, NULL, '0', '+'), '+');
				else if (dummy_A->pow != NULL && dummy_B->pow != NULL) // num*sym^(pow) * num*sym^(pow)
					new_pow = sum_diff(dummy_A->pow, dummy_B->pow, '+');
				else if (dummy_A->pow == NULL && dummy_B->pow == NULL) // num*sym * num*sym
					new_pow = create_point(2, 2, NULL, '0', '+');

				if (new_pow->number == 0 && new_pow->pnext == NULL) // num*sym^(0) == num
					dummy_C = create_point(2, dummy_A->number * dummy_B->number, NULL, '0', '+');
				else
					dummy_C = create_point(1, dummy_A->number * dummy_B->number, new_pow, dummy_A->symbol, '+');

				if ((dummy_A->operation == '+' && dummy_B->operation == '-') || (dummy_A->operation == '-' && dummy_B->operation == '+'))
					dummy_C->operation = '-'; // Если надо помеять на -

				if (dummy_C->what == 2)
					C = sum_diff(C, dummy_C, '+');
				else
					C = find_place(C, dummy_C);
			}
			else if (dummy_A->what == 1 && dummy_B->what == 2) // num*sym^(pow) * mul*num^(pow)
			{
				if (dummy_B->pow == NULL) // num*sym^(pow) * num
				{
					dummy_C = create_point(1, dummy_A->number * dummy_B->number, dummy_A->pow, dummy_A->symbol, '+');
					if ((dummy_A->operation == '+' && dummy_B->operation == '-') || (dummy_A->operation == '-' && dummy_B->operation == '+'))
						dummy_C->operation = '-'; // Если надо помеять на -
					C = find_place(C, dummy_C);
				}
				else if (dummy_B->pow != NULL) // num*sym^(pow) * mul*num^(pow)
				{
					// Для реализации придется вводить еще одну операцию *, много исправлять, вообще эта операция не обязательна по условию
				}
			}
			else if (dummy_A->what == 2 && dummy_B->what == 1) // mul*num^(pow) * num*sym^(pow)
			{
				if (dummy_A->pow == NULL) // num * num*sym^(pow)
				{
					dummy_C = create_point(1, dummy_A->number * dummy_B->number, dummy_B->pow, dummy_B->symbol, '+');
					if ((dummy_A->operation == '+' && dummy_B->operation == '-') || (dummy_A->operation == '-' && dummy_B->operation == '+'))
						dummy_C->operation = '-'; // Если надо помеять на -
					C = find_place(C, dummy_C);
				}
				else if (dummy_A->pow != NULL) // mul*num^(pow) * num*sym^(pow)
				{
					// Для реализации придется вводить еще одну операцию *, много исправлять, вообще эта операция не обязательна по условию
				}
			}
			else if (dummy_A->what == 2 && dummy_B->what == 2)
			{
				if (dummy_A->pow == NULL && dummy_B->pow == NULL)
				{
					dummy_C = create_point(2, dummy_A->number * dummy_B->number, dummy_B->pow, dummy_A->symbol, '+');
					if ((dummy_A->operation == '+' && dummy_B->operation == '-') || (dummy_A->operation == '-' && dummy_B->operation == '+'))
						dummy_C->operation = '-'; // Если надо помеять на -
					C = find_place(C, dummy_C);
				}
				else if (dummy_A->pow != NULL && dummy_B->pow == NULL)
				{
					dummy_C = create_point(2, dummy_A->mul * dummy_B->number, dummy_A->pow, dummy_A->symbol, '+');
					if ((dummy_A->operation == '+' && dummy_B->operation == '-') || (dummy_A->operation == '-' && dummy_B->operation == '+'))
						dummy_C->operation = '-'; // Если надо помеять на -
					C = find_place(C, dummy_C);
				}
				else if (dummy_A->pow == NULL && dummy_B->pow != NULL)
				{
					dummy_C = create_point(2, dummy_A->number * dummy_B->mul, dummy_A->pow, dummy_A->symbol, '+');
					if ((dummy_A->operation == '+' && dummy_B->operation == '-') || (dummy_A->operation == '-' && dummy_B->operation == '+'))
						dummy_C->operation = '-'; // Если надо помеять на -
					C = find_place(C, dummy_C);
				}
				else
				{
					// Для реализации придется вводить еще одну операцию *, много исправлять, вообще эта операция не обязательна по условию
				}
			}
			if (dummy_A->pnext != NULL)
				dummy_A = dummy_A->pnext;
			else break;
		}
		if (dummy_B->pnext != NULL)
			dummy_B = dummy_B->pnext;
		else
			return C;
	}
}

/*---------------Вывод полинома---------------*/
void print_pol(struct letters* A)
{
	struct letters* dummy = A;
	while (1)
	{
		if (dummy->number == 0 && dummy->pnext != NULL)
		{
			A = del(A, dummy);
			dummy = A;
		}
		else if (dummy->number == 0 && dummy->pprev != NULL)
		{
			A = del(A, dummy);
			dummy = A;
		}
		if (dummy->pnext != NULL)
			dummy = dummy->pnext;
		else break;
	}
	while (1)
	{
		if (A->what == 1)
		{
			if (A->pprev != NULL || A->operation == '-') // Если это не голова, то печатаем знак
				if (A->number != 0)
					printf("%c", A->operation);
			if (A->number != 1) // Если не стоит простое умножение на единицу
				printf("%d", A->number);
			if (A->number != 0)
			{
				printf("%c", A->symbol);
				if (A->pow != NULL && A->pow->pnext != NULL)
				{
					printf("^(");
					print_pol(A->pow);
					printf(")");
				}
				else if (A->pow != NULL)
				{
					printf("^");
					print_pol(A->pow);
				}
			}
		}
		else
		{
			if (A->pprev != NULL || A->operation == '-') // Если это не голова, то печатаем знак
				printf("%c", A->operation);
			printf("%d", A->number);
			if (A->pow != NULL)
			{
				printf("^(");
				print_pol(A->pow);
				printf(")");
			}
		}
		if (A->pnext != NULL)
			A = A->pnext;
		else
			return;
	}
}

/*---------------Удаление полинома---------------*/
void free_pol(struct letters* A)
{
	if (A->pnext != NULL)
		free_pol(A->pnext);
	if (A->pow != NULL)
		free_pol(A->pow);
	free(A);
}

/*---------------Для красивого вывода операций---------------*/
print(struct letters* A, struct letters* B, char c)
{
	print_pol(A);
	printf(" %c ", c);
	print_pol(B);
	printf(" = ");
}

/*---------------Удаление нулевых слагаемых---------------*/
struct letters* check_zero(struct letters* A)
{
	struct letters* dummy = A;
	while (1)
	{
		if (dummy->number == 0)
		{
			if (dummy->pnext != NULL)
				A = del(A, dummy);
			else if (dummy->pprev != NULL)
				A = del(A, dummy);
			else // Ни вперед ни назад
			{
				dummy->what = 2;
				break;
			}
			dummy = A;
			continue;
		}
		if (dummy->pnext != NULL)
			dummy = dummy->pnext;
		else break;
	}
	return A;
}

/*---------------Добавление новых переменных---------------*/
struct glob_var* add_to_glob(char sym, struct glob_var* head, struct letters* pol)
{
	struct glob_var* dummy = head;
	if (head == NULL) // Если еще нет ни одной глобальной переменной
	{
		head = (struct glob_var*)malloc(sizeof(struct glob_var));
		head->symbol = sym;
		head->var = pol;
		head->pnext = NULL;
		return head;
	}
	else // Если же имеется голова
	{
		// Производим поиск совпадения
		while (1)
		{
			if (dummy->symbol == sym) // Нашли совпадение, перезаписываем
			{
				free_pol(dummy->var);
				dummy->var = pol;
				return head;
			}
			if (dummy->pnext == NULL)
				break;
			else
				dummy = dummy->pnext;
		}
		// Если оказкались тут, значит не найдено совпадений
		dummy->pnext = (struct glob_var*)malloc(sizeof(struct glob_var));
		dummy = dummy->pnext;
		dummy->symbol = sym;
		dummy->var = pol;
		dummy->pnext = NULL;
		return head;
	}
}

/*---------------Получение переменной-полинома---------------*/
struct letters* get_var(char sym)
{
	if (var_head == NULL) // Вообще нет переменных
		return NULL;
	else
	{
		struct glob_var* dummy = var_head;
		while (1)
		{
			if (dummy->symbol == sym)
			{
				return copy_pol(dummy->var, NULL); // Нашли, возвращаем копию
			}
			if (dummy->pnext == NULL) // Так и не нашли
				return NULL;
			else dummy = dummy->pnext;
		}
	}
}

/*---------------Добавление результата в лист, для последующего вывода---------------*/
struct result* add_to_res(struct result* head, struct letters* point)
{
	if (head == NULL) // Ни одного ответа еще не было
	{
		head = (struct result*)malloc(sizeof(struct result));
		head->pnext = NULL;
		head->point = point;
	}
	else // Как минимум один ответ имеется
	{
		struct result* dummy = head;
		while (1)
		{
			if (dummy->pnext != NULL)
				dummy = dummy->pnext;
			else
			{
				dummy->pnext = (struct result*)malloc(sizeof(struct result));
				dummy = dummy->pnext;
				dummy->pnext = NULL;
				dummy->point = point;
				break;
			}
		}
	}
	return head;
}

/*---------------Вывод результата---------------*/
void print_res(struct result* head)
{
	if (head == NULL)
		return;
	print_pol(head->point);
	printf("\n");
	if (head->pnext != NULL)
		print_res(head->pnext);
}

/*---------------Удаление результата---------------*/
void free_res(struct result* head)
{
	if (head != NULL)
	{
		if (head->pnext != NULL)
		{
			free_pol(head->point);
			free_res(head->pnext);
			free(head);
		}
		else
		{
			free_pol(head->point);
			free(head);
		}
	}
}
%}

%start start
%token NEW_VAR VAR LF BAD_SYM SHOW POLYNOMIAL

%union { 
    int a; 
    char c;
    struct letters *point;
}

%code requires {
	/*---------------Структура необходимая для обработки ошибок со скобками---------------*/
	struct bracket_info
	{
		int line; // Номер строки
		int more_closing; // Если стоит 1, значит был случай, когда закрывающих скобок было больше чем закрывающих
		int opening_bracket; // Количество открывающих скобок
		int closing_bracket; // Закрывающих скобок
		struct bracket_info *pnext; // Указатель на узел следующей строки
	};
	struct bracket_info *bi_head;
}

%type <c> NEW_VAR VAR LF lf BAD_SYM SHOW show
%type <struct letters*> POLYNOMIAL polynomial each_line

%left '+' '-' /* Сохранен приоритет операций */
%left '*'
%right '^'
%right '('
%left ')'

%%
start: begin
	{
		if (global_find_error == 0)
		{
			print_res(res_head);
		}
		free_res(res_head);
	}
	;

begin: 
    | begin lf
	| begin error
    {
		find_error = 0;
    }
	| begin each_line
	{
		if ($<point>2 != NULL)
			free_pol($<point>2);
		find_error = 0;
	}
	| begin show each_line
	{
		if (find_error == 0)
			res_head = add_to_res(res_head, copy_pol($<point>3, NULL));
		if ($<point>3 != NULL)
			free_pol($<point>3);
		find_error = 0;
	}
    ;

show: SHOW
	{
		if(show_line == line)
			yyerror("Two operations show: and show: stand in one line");
		else
			show_line = line;
	}
	| show SHOW
	{
		yyerror("Two operations show: and show: stand in a row");
	}
	;

each_line: polynomial
	| NEW_VAR each_line
	{
		if ($<c>1 >= 'A' && $<c>1 <= 'Z') // Верное обозначение глобальной переменной
		{
			if (find_error == 0)
				var_head = add_to_glob($<c>1, var_head, copy_pol($<point>2, NULL));
			$<point>$ = $<point>2;
		}
		else
		{
			inc_var[31] = $<c>1;
			yyerror(inc_var);
			$<point>$ = create_point(2, 1, NULL, '0', '+');
		}
	}
	;

lf: LF
	{
		line++;
	}
	| lf LF
	{
		line++;
	}
	;

polynomial: polynomial '+' '^'
	{
		yyerror("Two operation symbols '+' and '^' stand in a row");
		$<point>$ = $<point>1;
	}
	| polynomial '-' '^'
	{
		yyerror("Two operation symbols '-' and '^' stand in a row");
		$<point>$ = $<point>1;
	}
	| polynomial '*' '^'
	{
		yyerror("Two operation symbols '*' and '^' stand in a row");
		$<point>$ = $<point>1;
	}
	| polynomial '^' '*'
	{
		yyerror("Two operation symbols '*' and '^' stand in a row");
		$<point>$ = $<point>1;
	}
	| polynomial '^' '^'
	{
		yyerror("Two operation symbols '^' and '^' stand in a row");
		$<point>$ = $<point>1;
	}
	| polynomial '*' '*'
	{
		yyerror("Two operation symbols '*' stand in a row");
		$<point>$ = $<point>1;
	}
	| '('')'
	{
		yyerror("There is no value between the brackets");
		$<point>$ = create_point(2, 1, NULL, '0', '+');
	}
	| BAD_SYM
	{	
		if ($<c>1 == '*') // Первым символом является '*'
		{
			bad_fir[21] = $<c>1;
			yyerror(bad_fir);
			$<point>$ = create_point(2, 1, NULL, '0', '+');
		}
		else if ($<c>1 == '^') // Первым символом является '^'
		{
			bad_fir[21] = $<c>1;
			yyerror(bad_fir);
			$<point>$ = create_point(2, 1, NULL, '0', '+');
		}
		else if ($<c>1 == ':') // Использована неправильная команда
		{
			yyerror("Used incorrect command, use show:");
			$<point>$ = create_point(2, 1, NULL, '0', '+');
		}
		else // Использован запрещенный символ
		{
			char mes[30] = "The forbidden symbol c is used";
			mes[21] = $<c>1;
			$<point>$ = create_point(2, 1, NULL, '0', '+');
			yyerror(mes);
		}
	}
	| VAR
	{
		if ($<c>1 >= 'A' && $<c>1 <= 'Z') // Верное обозначение глобальной переменной
		{
			$<point>$ = get_var($<c>1);
			if ($<point>$ == NULL)
			{
				yyerror("An uninitialized polynomial is used");
				$<point>$ = create_point(2, 1, NULL, '0', '+');
			}
		}
		else
		{
			inc_var[31] = $<c>1;
			yyerror(inc_var);
			$<point>$ = create_point(2, 1, NULL, '0', '+');
		}
	}
	| polynomial '^' polynomial
	{
		#ifdef __linux__
		if ($<point->number>3 == 0) // Все в нулевой степени
		{
			if($<point->number>1 == 0) // 0^0 - это неопределенность
			{
				yyerror("Indeterminate form 0^0 is used");
			}
			else
				$<point>$ = create_point(2, 1, NULL, '0', '+');
		}
		else if ($<point->what>1 == 1 && $<point->pnext>1 == NULL && $<point->what>3 == 1) // Переменная в степени с переменной
		{
			if ($<point->symbol>1 != $<point->symbol>3) // Разные переменные
			{
				dif_mes[24] = $<point->symbol>1;
				dif_mes[30] = $<point->symbol>3;
				yyerror(dif_mes);
				$<point>$ = $<point>1;
			}
			else // Можем возвести в степень
			{
				$<point->pow>1 = $<point>3;
				$<point>$ = $<point>1;
			}
		}
		else if ($<point->what>1 == 1 && $<point->pnext>1 != NULL && $<point->what>3 == 1) // Полином в степени с переменной
		{
			yyerror("There is a variable in the power of a polynomial. The power of a polynomial can only be a positive number or zero");
			$<point>$ = $<point>1;
		}
		else if ($<point->what>1 == 2 && $<point->what>3 == 1) // Число в степени с переменной
		{
			yyerror("There is a variable in the power of a number. The power of a number can only be a positive number");
			$<point>$ = $<point>1;
		}
		else if ($<point->what>1 == 1 && $<point->pnext>1 == NULL && $<point->what>3 == 2 && $<point->operation>3 == '-') // Переменная в отрицательной степени
		{
			yyerror("There is a negative number in the power of the variable. The power of a variable can only be a polynomial, positive number or zero");
			$<point>$ = $<point>1;
		}
		else if ($<point->what>1 == 1 && $<point->what>3 == 2 && $<point->operation>3 == '-') // Полином в отрицательной степени
		{
			yyerror("There is a negative number in the power of the polynomial. The power of a polynomial can only be a positive number or zero");
			$<point>$ = $<point>1;
		}
		else if ($<point->what>1 == 2 && $<point->what>3 == 2 && $<point->operation>3 == '-') // Число в отрицательной степени
		{
			yyerror("There is a negative number in the power of the number. The power of a number can only be a positive number");
			$<point>$ = $<point>1;
		}
		else // Все в степени числа
		{
			$<point>$ = $<point>1;
			for (int j = 1; j < $<point->number>3; j++)
			{
				$<point>$ = multiplication($<point>$, $<point>1);
			}
		}
		#elif _WIN32
		if ($<point>3->number == 0) // Все в нулевой степени
		{
			if($<point>1->number == 0) // 0^0 - это неопределенность
			{
				yyerror("Indeterminate form 0^0 is used. The power of a number can only be a positive number");
			}
			else
				$<point>$ = create_point(2, 1, NULL, '0', '+');
		}
		else if ($<point>1->what == 1 && $<point>1->pnext == NULL && $<point>3->what == 1) // Переменная в степени с переменной
		{
			if ($<point>1->symbol != $<point>3->symbol) // Разные переменные
			{
				dif_mes[24] = $<point>1->symbol;
				dif_mes[30] = $<point>3->symbol;
				yyerror(dif_mes);
				$<point>$ = $<point>1;
			}
			else // Можем возвести в степень
			{
				$<point>1->pow = $<point>3;
				$<point>$ = $<point>1;
			}
		}
		else if ($<point>1->what == 1 && $<point>1->pnext != NULL && $<point>3->what == 1) // Полином в степени с переменной
		{
			yyerror("There is a variable in the power of a polynomial. The power of a polynomial can only be a positive number or zero");
			$<point>$ = $<point>1;
		}
		else if ($<point>1->what == 2 && $<point>3->what == 1) // Число в степени с переменной
		{
			yyerror("There is a variable in the power of a number. The power of a number can only be a positive number");
			$<point>$ = $<point>1;
		}
		else if ($<point>1->what == 1 && $<point>1->pnext == NULL && $<point>3->what == 2 && $<point>3->operation == '-') // Переменная в отрицательной степени
		{
			yyerror("There is a negative number in the power of the variable. The power of a variable can only be a polynomial, positive number or zero");
			$<point>$ = $<point>1;
		}
		else if ($<point>1->what == 1 && $<point>3->what == 2 && $<point>3->operation == '-') // Полином в отрицательной степени
		{
			yyerror("There is a negative number in the power of the polynomial. The power of a polynomial can only be a positive number or zero");
			$<point>$ = $<point>1;
		}
		else if ($<point>1->what == 2 && $<point>3->what == 2 && $<point>3->operation == '-') // Число в отрицательной степени
		{
			yyerror("There is a negative number in the power of the number. The power of a number can only be a positive number");
			$<point>$ = $<point>1;
		}
		else // Все в степени числа
		{
			$<point>$ = $<point>1;
			for (int j = 1; j < $<point->number>3; j++)
			{
				$<point>$ = multiplication($<point>$, $<point>1);
			}
		}
		#endif
	}
	| polynomial '*' polynomial
	{
		#ifdef __linux__
		if ($<point->what>1 == 1 && $<point->what>3 == 1 && ($<point->symbol>1 != $<point->symbol>3)) // Разные переменные
		{
			dif_mes[24] = $<point->symbol>1;
			dif_mes[30] = $<point->symbol>3;
			yyerror(dif_mes);
			$<point>$ = $<point>1;
		}
		else
			$<point>$ = multiplication($<point>1, $<point>3);
		#elif _WIN32
		if ($<point>1->what == 1 && $<point>3->what == 1 && ($<point>1->symbol != $<point>3->symbol)) // Разные переменные
		{
			dif_mes[24] = $<point>1->symbol;
			dif_mes[30] = $<point>3->symbol;
			yyerror(dif_mes);
			$<point>$ = $<point>1;
		}
		else
			$<point>$ = multiplication($<point>1, $<point>3);
		#endif
	}
	| '(' polynomial ')'
	{
		#ifdef __linux__
		$<point>$ = $<point>2;
		$<point->br_check>$ = '1';
		$<point->op_check>$ = '0';
		#elif _WIN32
		$<point>$ = $<point>2;
		$<point>$->br_check = '1';
		$<point>$->op_check = '0';
		#endif
	}
	| polynomial polynomial
	{
		#ifdef __linux__
		if ($<point->br_check>2 != '0') // Нет операции между скобок
		{
			yyerror("There is no operation between brackets");
			$<point>$ = $<point>1;
		}
		else if ($<point->what>1 == 1 && $<point->what>2 == 1 && ($<point->symbol>1 != $<point->symbol>2)) // Разные переменные
		{
			dif_mes[24] = $<point->symbol>1;
			dif_mes[30] = $<point->symbol>2;
			yyerror(dif_mes);
			$<point>$ = $<point>1;
		}
		else
		{
			$<point>$ = check_zero(sum_diff($<point>1, $<point>2, '+'));
			$<point->op_check>$ = '0';
		}
		#elif _WIN32
		if ($<point>2->br_check != '0') // Нет операции между скобок
		{
			yyerror("There is no operation between brackets");
			$<point>$ = $<point>1;
		}
		else if ($<point>1->what == 1 && $<point>2->what == 1 && ($<point>1->symbol != $<point>2->symbol)) // Разные переменные
		{
			dif_mes[24] = $<point>1->symbol;
			dif_mes[30] = $<point>2->symbol;
			yyerror(dif_mes);
			$<point>$ = $<point>1;
		}
		else
		{
			$<point>$ = check_zero(sum_diff($<point>1, $<point>2, '+'));
			$<point>$->op_check = '0';
		}
		#endif
	}
	| '+' polynomial
	{
		#ifdef __linux__
		if ($<point->op_check>2 == '+')
			yyerror("Two operation symbols '+' stand in a row");
		else if ($<point->op_check>2 == '-')
			yyerror("Two operation symbols '+' and '-' stand in a row");
		$<point>$ = $<point>2;
		$<point->br_check>$ = '0';
		$<point->op_check>$ = '+';
		#elif _WIN32
		if ($<point>2->op_check == '+')
			yyerror("Two operation symbols '+' stand in a row");
		else if ($<point>2->op_check == '-')
			yyerror("Two operation symbols '+' and '-' stand in a row");
		$<point>$ = $<point>2;
		$<point>$->br_check = '0';
		$<point>$->op_check = '+';
		#endif
	}
	| '-' polynomial
	{
		#ifdef __linux__
		if ($<point->op_check>2 == '-')
		{
			yyerror("Two operation symbols '-' stand in a row");
			$<point>$ = $<point>2;
		}
		else if ($<point->op_check>2 == '+')
		{
			yyerror("Two operation symbols '-' and '+' stand in a row");
			$<point>$ = $<point>2;
		}
		$<point>$ = multiplication($<point>2, create_point(2, 1, NULL, '0', '-'));
		$<point->br_check>$ = '0';
		$<point->op_check>$ = '-';
		#elif _WIN32
		if ($<point>2->op_check == '-')
		{
			yyerror("Two operation symbols '-' stand in a row");
			$<point>$ = $<point>2;
		}
		else if ($<point>2->op_check == '+')
		{
			yyerror("Two operation symbols '-' and '+' stand in a row");
			$<point>$ = $<point>2;
		}
		$<point>$ = multiplication($<point>2, create_point(2, 1, NULL, '0', '-'));
		$<point>$->br_check = '0';
		$<point>$->op_check = '-';
		#endif
	}
	| POLYNOMIAL
	{
		$<point>$ = $<point>1;
	}
	;
%%

main()
{
	#if YYDEBUG
	//yydebug = 1;
	#endif 
    yyin = fopen("input.txt", "r");
    yyparse();
}

yyerror(char *s)
{
	global_find_error++;
	find_error++;
	struct bracket_info *dummy = bi_head; // Производим проверку на ошибоку в скобках
	if (dummy != NULL && s[0] == 's' && s[1] == 'y')
	{
		while(1)
		{
			if (dummy->line == line)
			{
				if (dummy->opening_bracket > dummy->closing_bracket)
					fprintf(stderr, "ERROR: line: %d. There are more opening brackets than closing ones, maybe incorrect sequence.\n", line);
				else if (dummy->opening_bracket < dummy->closing_bracket)
					fprintf(stderr, "ERROR: line: %d. There are more closing brackets than opening ones, maybe incorrect sequence.\n", line);
				else if (dummy->more_closing != 0) // Была ошибка в последовательности: ())(
					fprintf(stderr, "ERROR: line: %d. Incorrect sequence of brackets.\n", line);
				else fprintf(stderr, "ERROR: line: %d. %s.\n", line, s);
				break;
			}
			else if (dummy->pnext != NULL)
				dummy = dummy->pnext;
			else
			{
				fprintf(stderr, "ERROR: line: %d. %s.\n", line, s);
				break;
			}
		}
	}
	else fprintf(stderr, "ERROR: line: %d. %s.\n", line, s);
}

yywrap()
{
    fclose(yyin);
    return(1);
}