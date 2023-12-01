#!/bin/bash

# Database connection details
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="4710.FP"
DB_USER="alexanderharris17"

# Function to connect to the PostgreSQL database
connect_db() {
    psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -c "$1"
}


# Admin roles add_book & remove_book

# Function to add a book to the database
add_book() {
    # Prompt the user for book details
    echo "Enter details for the new book:"
    read -p "Title: " title
    read -p "Author: " author
    read -p "Book ID: " book_id
    read -p "Grade Level: " grade_level

    # Construct the SQL command with user-input values
    sql_command="INSERT INTO books (title, author, book_id, grade_level, availability) VALUES ('$title', '$author', '$book_id', '$grade_level', true);"

    # Connect to the database and execute the SQL command
    connect_db "$sql_command"
}
# Function to remove a book from the database
remove_book() {
    # Prompt the user for book id to remove
    read -p "Enter book id to remove: " book_id

    # Construct the SQL command to delete data based on book_id
    sql_command="DELETE FROM books WHERE book_id='$book_id';"

    # Connect to the database and execute the SQL command
    connect_db "$sql_command"
}




#Staff role to display all books available or not 

# Function to show all books in the database (staff)
show_all_books() {
    echo "All books in the database:"
    psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -c "SELECT * FROM books;"
}



# Student roles to search & borrow and return books. 


# Function to search and display available books based on user's grade level
search_and_borrow_book() {
    connect_db
    if [ "$USER_TYPE" == "student" ]; then
        # Prompt the user for their grade level
        read -p "Enter your grade level (13-16): " user_grade_level

        # Validate the user's grade level (you can customize this validation)
        if ! [[ "$user_grade_level" =~ ^[1][3-6]$ ]]; then
            echo "Invalid grade level. Exiting..."
            exit 1
        fi

        # Display available books at the specified grade level
        echo "Available books for grade level $user_grade_level:"
        psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -c "SELECT * FROM books WHERE grade_level = $user_grade_level AND availability = true;"

        # Prompt the user to enter the book ID to borrow
        read -p "Enter the book ID to borrow: " book_id

        # Check if the selected book is available
        available=$(psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -t -c "SELECT availability FROM books WHERE book_id = $book_id AND availability = true;")

        available=$(echo "$available" | tr -d '[:space:]')
        echo "Debug: Availability - $available"

        if [ "$available" == "t" ]; then
            # Call the SQL function to borrow the book
            echo "SELECT borrow_book($book_id, '$USER_TYPE', $user_grade_level);" | connect_db
            echo "UPDATE books SET availability = false WHERE book_id = $book_id;" | connect_db
            echo "Borrowing book with ID: $book_id"
            # Add additional borrowing logic here
        else
            echo "Book not found or not available for borrowing."
        fi
    else
        # For staff and admin, display all available books
        echo "Available books:"
        psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -c "SELECT * FROM books WHERE availability = true;"
    fi
}
    
# Function to return a book
return_book() {
    connect_db
    read -p "Enter book id, title, or author to return: " return_term

    # Check if the book is borrowed
    borrowed=$(echo "SELECT * FROM borrowed_books WHERE book_id='$return_term' OR title='$return_term' OR author='$return_term';" | psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -W -t)

    if [ -z "$borrowed" ]; then
        echo "Book not found or not borrowed."
    else
        echo "Returning book: $borrowed"
        # Add returning logic here
    fi
}






# Main script
echo "Welcome to the Bookstore Management System!"

# Get user credentials
read -p "Enter your username: " username
read -s -p "Enter your password: " password
echo

# Authenticate users
if [ "$username" == "admin" ] && [ "$password" == "admin1" ]; then
    USER_TYPE="admin"
    echo "Admin actions:"
    echo "1. Add a book"
    echo "2. Remove a book"
    read -p "Select an option: " admin_option

    case $admin_option in
        1) add_book ;;
        2) remove_book ;;
        *) echo "Invalid option. Exiting..."; exit 1 ;;
    esac
elif [ "$username" == "staff" ] && [ "$password" == "staff1" ]; then
    USER_TYPE="staff"
    echo "Staff actions:"
    echo "1. Show all books"
    read -p "Select an option: " staff_option

    case $staff_option in
        1) show_all_books ;;
        *) echo "Invalid option. Exiting..."; exit 1 ;;
    esac

elif [ "$username" == "student" ] && [ "$password" == "student1" ]; then
    USER_TYPE="student"
    echo "Student actions:"
    echo "1. Search for a book to borrow"
    echo "2. Return a book"
    read -p "Select an option: " student_option

    case $student_option in
        1) search_and_borrow_book ;;
        2) return_book ;;
        *) echo "Invalid option. Exiting..."; exit 1 ;;
    esac
else
    echo "Invalid username or password. Exiting..."
    exit 1
fi
