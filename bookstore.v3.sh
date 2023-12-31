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
    echo "Enter details for the new book:"
    read -p "Title: " title
    read -p "Publication Year: " publication_year
    read -p "Copies Available: " copies_available
    read -p "Author ID: " author_id

    sql_command="INSERT INTO books (Title, Publication_Year, Copies_Available, Author_ID) VALUES ('$title', '$publication_year', '$copies_available', '$author_id');"
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



# Student roles to borrow and return books. 


# Function to search and display available books based on user's grade level
# Function to search and display available books based on user's grade level
search_and_borrow_book() {
    connect_db
    if [ "$USER_TYPE" == "student" ]; then
        # Display available authors and their biographies
        echo "Available authors and their biographies:"
        psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -c "SELECT name, biography FROM author;"

        # Prompt the user to enter the author's name to retrieve books
        read -p "Enter the author's name to retrieve books: " author_name

        # Display available books for the selected author
        echo "Available books by $author_name:"
        psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -c "SELECT * FROM books WHERE author_id = (SELECT author_id FROM author WHERE name = '$author_name') AND availability = true;"

        # Prompt the user to enter the book ID to borrow
        read -p "Enter the book ID to borrow: " book_id

        # Check if the selected book is available
        available=$(psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -t -c "SELECT availability FROM books WHERE book_id = '$book_id' AND availability = true;")

        available=$(echo "$available" | tr -d '[:space:]')
        echo "Debug: Availability - $available"

        if [ "$available" == "t" ]; then
            # Call the SQL function to borrow the book
            echo "SELECT borrow_book($book_id, '$USER_TYPE', null);" | connect_db
            echo "UPDATE books SET availability = false WHERE book_id = $book_id;" | connect_db
            echo "Borrowing book with ID: $book_id"
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
        echo "UPDATE books SET availability = true WHERE book_id = '$return_term' OR title='$return_term' OR author='$return_term';" | connect_db
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
    echo "1. Add an author"
    echo "2. Add a member"
    echo "3. Add a book"
    read -p "Select an option: " admin_option

    case $admin_option in
            1) add_author ;;
            2) add_member ;;
            3) add_book ;;
            *) echo "Invalid option. Exiting..."; exit 1 ;;
        esac
elif [ "$username" == "staff" ] && [ "$password" == "staff1" ]; then
    USER_TYPE="staff"
    echo "Staff actions:"
    echo "1. Show all books"
    read -p "Select an option: " staff_option

    case $staff_option in
        1) show_all_books ;
         echo "Invalid option. Exiting..."; exit 1 ;;
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
