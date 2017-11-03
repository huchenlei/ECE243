#include <stdio.h>
#include <stdlib.h>

#define true 1
#define false 0
#define MAX_CHILDREN_NUM 5
#define MAX_LEVEL_OF_GROUPS 10 // MAX support 10 level of groups
#define MAX_PARALLEL_OF_GROUPS 10

typedef struct re_node {
    char char_match;  // the char this unit matches

    int num_of_parent; // used to free memory when deleting tree
    int num_of_children;
    struct re_node *children_nodes[MAX_CHILDREN_NUM];
} re_node;

// constructor
re_node *new_node(char c) {
    re_node *node = malloc(sizeof(re_node));
    node->char_match = c;
    node->num_of_children = 0;
    node->num_of_parent = 1;
    for (int i = 0; i < MAX_CHILDREN_NUM; ++i) {
        node->children_nodes[i] = NULL;
    }
    return node;
}

// compile re
re_node *construct_tree(char *re);

int match_char(re_node *this, char *current_char);

void delete_tree(re_node *root);

void print_tree(re_node *root, int node_level);

// sinple re, only support & | ()
int re_match(char *re, char *text) {
    // construct re node tree
    re_node *root = construct_tree(re);
    // recursively call match char
    int result = false;
    for (int i = 0; i < root->num_of_children; ++i) {
        result = result || match_char(root->children_nodes[i], text);
    }
    delete_tree(root);
    return result;
}

int main(int argc, char const *argv[]) {
//    re_node *root = construct_tree("(a)|(xss)|(bad)@gmail.com");
//    print_tree(root, 0);
    printf("match result: %d", re_match("(a)|(x)|(b)@gmail.com", "a@gmail.coc"));
    return 0;
}

re_node *construct_tree(char *re) {
    int current_bracket_level = 0;
    re_node *front_level_char[MAX_LEVEL_OF_GROUPS];
    int parallel_num = 0;
    re_node *parallel_tails[MAX_PARALLEL_OF_GROUPS];

    int prev_is_group = false;
    re_node *root = new_node('\0');

    re_node *current_node = root;
    while (*re != '\0') {
        if (*re == '(') {
            prev_is_group = false;
            front_level_char[current_bracket_level] = current_node;
            current_bracket_level++;
        } else if (*re == ')') {
            prev_is_group = true;
            current_bracket_level--;
        } else if (*re == '|') {
            if (prev_is_group) {
                parallel_tails[parallel_num] = current_node;
                parallel_num++;
                current_node = front_level_char[current_bracket_level];
            }
            prev_is_group = false;
        } else {
            // append new children node to current node
            int node_index = current_node->num_of_children;
            current_node->children_nodes[node_index] = new_node(*re);
            current_node->num_of_children++;
            current_node->children_nodes[node_index]->num_of_parent += current_node->num_of_parent - 1;
            current_node = current_node->children_nodes[node_index];

            // consider or case
            if (prev_is_group) {
                for (int i = 0; i < parallel_num; ++i) {
                    parallel_tails[i]->children_nodes[parallel_tails[i]->num_of_children] = current_node;
                    parallel_tails[i]->num_of_children++;
                    current_node->num_of_parent++;
                }
                parallel_num = 0;
            }
            prev_is_group = false;
        }
        re++;
    }
    return root;
}

int match_char(re_node *this, char *current_char) {
    int children_result = false;
    for (int i = 0; i < this->num_of_children; ++i) {
        children_result = children_result || match_char(this->children_nodes[i], current_char + 1);
    }
    printf("Char match: %c, %c\n", this->char_match, *current_char);
    if (this->num_of_children == 0) {
        if (*(current_char + 1) != '\0') return false; else children_result = true;
    }
    return (this->char_match == *current_char) && children_result;
}

void print_tree(re_node *root, int node_level) {
    printf("Node char: %c, Node level: %d, Children num: %d, Address: %p\n",
           root->char_match, node_level, root->num_of_children, &root);
    for (int i = 0; i < root->num_of_children; i++) {
        print_tree(root->children_nodes[i], node_level + 1);
    }
}

void delete_tree(re_node* root) {
    for (int i = 0; i < root->num_of_children; ++i) {
        delete_tree(root->children_nodes[i]);
    }
    root->num_of_parent--;
    if(root->num_of_parent == 0)
        free(root);
}