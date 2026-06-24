NAME = libasm.a
COMPILER = nasm
FORMAT = elf64
RM = rm -rf
AR = ar rcs

SRCS =  mandatory_part/ft_strlen.s \
        mandatory_part/ft_read.s \
        mandatory_part/ft_strcmp.s \
        mandatory_part/ft_strcpy.s \
        mandatory_part/ft_write.s \
        mandatory_part/ft_strdup.s \
		mandatory_part/ft_putstr.s

SRCS_BONUS =	bonus_part/ft_list_push_front.s \
				bonus_part/ft_list_size.s \
				bonus_part/ft_list_sort.s \
				bonus_part/ft_list_remove_if.s \
				bonus_part/ft_atoi_base.s

OBJS = $(SRCS:.s=.o)
OBJS_BONUS = $(SRCS_BONUS:.s=.o)

RED     := \033[31m
YELLOW  := \033[33m
GREEN   := \033[32m
BLUE    := \033[34m
RESET   := \033[0m

all: $(NAME)

$(NAME): $(OBJS)
	@echo "$(BLUE)Creating $(NAME)...$(RESET)"
	@$(AR) $(NAME) $(OBJS)

%.o: %.s
	@echo "$(GREEN)Compiling $<$(RESET)"
	@$(COMPILER) -f $(FORMAT) $< -o $@

clean:
	@echo "$(BLUE)Cleaning objects...$(RESET)"
	@$(RM) $(OBJS) $(OBJS_BONUS)

fclean: clean
	@echo "$(BLUE)Removing $(NAME)...$(RESET)"
	@$(RM) $(NAME)

re: fclean all

bonus: $(OBJS) $(OBJS_BONUS)
	@echo "$(BLUE)Creating with bonus $(NAME)...$(RESET)"
	@$(AR) $(NAME) $(OBJS) $(OBJS_BONUS)

.PHONY: all clean fclean re bonus