#include "main.h"

#define GRN "\033[0;32m"
#define RED "\033[0;31m"
#define CYN "\033[0;36m"
#define YEL "\033[0;33m"
#define RST "\033[0m"

static void free_all()
{

}

static void	print_header(const char *title)
{
	printf("\n" CYN "=== %s ===" RST "\n", title);
}

static void	check_int(const char *label, int mine, int real)
{
	if (mine == real)
		printf(GRN "[OK]" RST " %s => %d\n", label, mine);
	else
		printf(RED "[KO]" RST " %s => mine: %d | real: %d\n", label, mine, real);
}

static void	check_size(const char *label, size_t mine, size_t real)
{
	if (mine == real)
		printf(GRN "[OK]" RST " %s => %zu\n", label, mine);
	else
		printf(RED "[KO]" RST " %s => mine: %zu | real: %zu\n", label, mine, real);
}

static void	check_str(const char *label, const char *mine, const char *real)
{
	if (mine && real && strcmp(mine, real) == 0)
		printf(GRN "[OK]" RST " %s => \"%s\"\n", label, mine);
	else
		printf(RED "[KO]" RST " %s => mine: \"%s\" | real: \"%s\"\n", label,
			mine ? mine : "(null)", real ? real : "(null)");
}

/* ------------------------------------------------------------------ */

int	main(void)
{
	/* ---- FT_STRLEN ---- */
	print_header("FT_STRLEN");
	check_size("\"Hello World\"", ft_strlen("Hello World"), strlen("Hello World"));
	check_size("\"\"           ", ft_strlen(""),            strlen(""));
	check_size("\"a\"          ", ft_strlen("a"),           strlen("a"));

	/* ---- FT_STRCMP ---- */
	print_header("FT_STRCMP");
	check_int("\"abc\" vs \"abc\"", ft_strcmp("abc", "abc") == 0,  strcmp("abc", "abc") == 0);
	check_int("\"abc\" vs \"abd\"", ft_strcmp("abc", "abd") < 0,   strcmp("abc", "abd") < 0);
	check_int("\"abd\" vs \"abc\"", ft_strcmp("abd", "abc") > 0,   strcmp("abd", "abc") > 0);
	check_int("\"\"    vs \"\"   ", ft_strcmp("", "")       == 0,  strcmp("", "")       == 0);

	/* ---- FT_STRCPY ---- */
	print_header("FT_STRCPY");
	char	dest_mine[100];
	char	dest_real[100];
	ft_strcpy(dest_mine, "Hello libasm!");
	strcpy(dest_real,    "Hello libasm!");
	check_str("\"Hello libasm!\"", dest_mine, dest_real);
	ft_strcpy(dest_mine, "");
	strcpy(dest_real,    "");
	check_str("\"\" (empty)      ", dest_mine, dest_real);

	/* ---- FT_STRDUP ---- */
	print_header("FT_STRDUP");
	char	*mine_dup = ft_strdup("42 Network");
	char	*real_dup = strdup("42 Network");
	check_str("\"42 Network\"", mine_dup, real_dup);
	free(mine_dup);
	free(real_dup);
	mine_dup = ft_strdup("");
	real_dup = strdup("");
	check_str("\"\" (empty)  ", mine_dup, real_dup);
	free(mine_dup);
	free(real_dup);

	/* ---- FT_WRITE ---- */
	print_header("FT_WRITE");
	ssize_t	wret_mine = ft_write(1, "ft_write output\n", 16);
	ssize_t	wret_real = write(1,    "   write output\n", 16);
	check_int("return value (16)", (int)wret_mine, (int)wret_real);

	printf(YEL "-- Error test (fd = -1) --\n" RST);
	ssize_t	werr_mine = ft_write(-1, "x", 1);
	ssize_t	werr_real = write(-1,    "x", 1);
	check_int("return value (-1)", (int)werr_mine, (int)werr_real);
	check_int("errno match      ", errno,          errno); /* same process */

	/* ---- FT_READ ---- */
	print_header("FT_READ");
	printf(YEL "-- Error test (fd = -1) --\n" RST);
	char	buf[8];
	ssize_t	rerr_mine = ft_read(-1, buf, 4);
	ssize_t	rerr_real = read(-1,    buf, 4);
	check_int("return value (-1)", (int)rerr_mine, (int)rerr_real);

	/* ---- BONUS: FT_LIST ---- */
	print_header("FT_LIST_PUSH_FRONT + FT_LIST_SIZE");
	t_list	*lst = NULL;
	ft_list_push_front(&lst, "apple");
	ft_list_push_front(&lst, "banana");
	ft_list_push_front(&lst, "cherry");
	check_int("size after 3 pushes", ft_list_size(lst), 3);

	printf("\nList (unsorted): ");
	t_list *cur = lst;
	while (cur) { printf("[%s] ", (char *)cur->data); cur = cur->next; }

	/* ---- FT_LIST_SORT ---- */
	print_header("FT_LIST_SORT");
	ft_list_sort(&lst, (int (*)())ft_strcmp);
	printf("List (sorted):   ");
	cur = lst;
	while(cur)
	{
		printf("[%s] ", (char *)cur->data);
		cur = cur->next;
	}
	printf("\n");

	/* ---- FT_LIST_REMOVE_IF ---- */
	print_header("FT_LIST_REMOVE_IF");
	ft_list_remove_if(&lst, "banana", &ft_strcmp, &free_all);
	check_int("size after removing \"banana\"", ft_list_size(lst), 2);
	printf("List after remove: ");
	cur = lst;
	while (cur) { printf("[%s] ", (char *)cur->data); cur = cur->next; }
	printf("\n");

	/* ---- FT_ATOI_BASE ---- */
	print_header("FT_ATOI_BASE");
	check_int("\"42\"  base10  ", ft_atoi_base("42",     "0123456789"),       42);
	check_int("\"-42\" base10  ", ft_atoi_base("-42",    "0123456789"),       -42);
	check_int("\"101010\" base2", ft_atoi_base("101010", "01"),               42);
	check_int("\"ff\"  base16  ", ft_atoi_base("ff",     "0123456789abcdef"), 255);
	check_int("\"52\"  base8   ", ft_atoi_base("52",     "01234567"),         42);
	check_int("bad base (\"\")  ", ft_atoi_base("42",    ""),                  0);
	check_int("bad base (dup) ", ft_atoi_base("42",     "00123"),              0);

	/* free list */
	t_list *tmp;
	while (lst)
	{
		tmp = lst->next;
		free(lst);
		lst = tmp;
	}

	printf("\n");
	return (0);
}