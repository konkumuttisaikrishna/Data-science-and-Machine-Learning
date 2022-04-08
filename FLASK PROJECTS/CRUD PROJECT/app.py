from flask import Flask, render_template, request, redirect, url_for, flash
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
import os



crud = Flask(__name__)
crud.secret_key = "Secret Key"
#SqlAlchemy Database Configuration With Mysql
basedir = os.path.abspath(os.path.dirname(__file__))
crud.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(basedir, 'my_data.sqlite')
crud.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(crud)
Migrate(crud, db)


#Creating model table for our CRUD database
class Data(db.Model):
    id = db.Column(db.Integer, primary_key = True)
    name = db.Column(db.String(100))
    email = db.Column(db.String(100))
    phone = db.Column(db.String(100))


    def __init__(self, name, email, phone):

        self.name = name
        self.email = email
        self.phone = phone





#This is the index route where we are going to
#query on all our employee data
@crud.route('/')
def Index():
    all_data = Data.query.all()

    return render_template("index.html", employees = all_data)



#this route is for inserting data to mysql database via html forms
@crud.route('/insert', methods = ['POST'])
def insert():

    if request.method == 'POST':

        name = request.form['name']
        email = request.form['email']
        phone = request.form['phone']


        my_data = Data(name, email, phone)
        db.session.add(my_data)
        db.session.commit()

        flash("Employee Inserted Successfully")

        return redirect(url_for('Index'))


#this is our update route where we are going to update our employee
@crud.route('/update', methods = ['GET', 'POST'])
def update():

    if request.method == 'POST':
        my_data = Data.query.get(request.form.get('id'))

        my_data.name = request.form['name']
        my_data.email = request.form['email']
        my_data.phone = request.form['phone']

        db.session.commit()
        flash("Employee Updated Successfully")

        return redirect(url_for('Index'))




#This route is for deleting our employee
@crud.route('/delete/<id>/', methods = ['GET', 'POST'])
def delete(id):
    my_data = Data.query.get(id)
    db.session.delete(my_data)
    db.session.commit()
    flash("Employee Deleted Successfully")

    return redirect(url_for('Index'))






if __name__ == "__main__":
    crud.run(debug=True)
