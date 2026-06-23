#include "main.h"

void	ft_free_content_node()
{
    // free(data);
}

int	main(void)
{
// 	char	buffer[100];
// 	char	dest[100];

// 	// FT_STRLEN
// 	printf("=== FT_STRLEN ===\n");
// 	printf("Mine : %zu\n", ft_strlen("Hello World"));
// 	printf("Real : %zu\n\n", strlen("Hello World"));

// 	// FT_STRCMP
// 	printf("=== FT_STRCMP ===\n");
// 	printf("Mine : %d\n", ft_strcmp("abc", "abd"));
// 	printf("Real : %d\n\n", strcmp("abc", "abd"));

// 	// FT_STRCPY
// 	printf("=== FT_STRCPY ===\n");
// 	ft_strcpy(dest, "Salut depuis libasm");
// 	printf("Copied : %s\n\n", dest);

//     // FT_STRDUP
// 	printf("=== FT_STRDUP ===\n");
//     char *str = ft_strdup("abc");
//     char *str2 = strdup("abc");

// 	printf("Mine : %s\n", str);
// 	printf("Real : %s\n\n", str2);

//     free(str);
//     free(str2);

// 	// FT_WRITE
// 	printf("=== FT_WRITE ===\n");
// 	ft_write(1, "Message via ft_write\n", 21);
// 	write(1, "Message via write\n\n", 19);

	// FT_READ
	// printf("=== FT_READ ===\n");

	// memset(buffer, 0, sizeof(buffer));
	// ft_read(0, buffer, 99);
	// ft_putstr(buffer);

	t_list *lst = NULL;
	char *data1 = "test";
	char *data2 = "test";
	char *data3 = "a";
	ft_list_push_front(&lst, data1);
	ft_list_push_front(&lst, data2);
	ft_list_push_front(&lst, data3);

	t_list *current = lst;
	while (current)
	{
		ft_write(1, current->data, ft_strlen((char *)current->data));
		ft_write(1, "\n", 1);
		current = current->next;
	}

	// int result;
	// result = ft_list_size(lst);
	// printf("Size lst: %d\n", result);

	// current = lst;
	// ft_list_sort(&current, &ft_strcmp);

	// current = lst;
	// while (current)
	// {
	// 	if (!current->data)
	// 		ft_write(1, current->data, ft_strlen((char *)current->data));
	// 	else
	// 		printf("NULL");
	// 	ft_write(1, "\n", 1);
	// 	current = current->next;
	// }

	current = lst;
	char *element = "test";
	ft_list_remove_if(&current, element, &ft_strcmp, &ft_free_content_node);

	puts("prout");

	current = lst;
	while (current)
	{
		if (current->data)
			ft_write(1, current->data, ft_strlen((char *)current->data));
		else
			printf("NULL");
		ft_write(1, "\n", 1);
		current = current->next;
	}

	t_list *tmp;
	while (lst)
	{
		tmp = lst->next;
		free(lst);
		lst = tmp;
	}

	return (0);
}
