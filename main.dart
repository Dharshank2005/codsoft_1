import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; // Import for generating unique IDs

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // Assuming you have initialTransactions defined elsewhere
  final List<Transaction> initialTransactions = []; // Replace with actual data

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider<TransactionProvider>(
        create: (context) {
          final transactionProvider = TransactionProvider();
          transactionProvider.addTransactions(initialTransactions);
          return transactionProvider;
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Transaction List'),
            backgroundColor: Colors.blue,
          ),
          body: Column(
            children: [
              // Display current balance
              Consumer<TransactionProvider>(
                builder: (context, transactionProvider, _) {
                  return Text(
                    'Balance: \$${transactionProvider.balance.toStringAsFixed(2)}',
                  );
                },
              ),
              const Divider(),
              // Fix: Access _categoryDropdownValue from within AddTransactionForm
              AddTransactionForm(
                onAddTransaction: (transaction, category) =>
                    Provider.of<TransactionProvider>(context, listen: false)
                        .addTransaction(transaction, category),
              ),
              const Divider(),
              Expanded(
                child: TransactionList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Transaction Model (no changes)
class Transaction {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  String? category;

  Transaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.category,
  });
}

// Transaction List Widget
class TransactionList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, _) {
        return ListView.builder(
          itemCount: transactionProvider.transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactionProvider.transactions[index];
            return ListTile(
              title: Text(transaction.description),
              subtitle: Text(DateFormat.yMMMd().format(transaction.date)),
              trailing: Text('\$${transaction.amount.toStringAsFixed(2)}'),
            );
          },
        );
      },
    );
  }
}

// State Management Class
class TransactionProvider extends ChangeNotifier {
  final List<Transaction> transactions = [];
  final Map<int, double> _monthlyBudgets = {};
  double _balance = 0.0; // Use a private variable for balance

  double get balance => _balance; // Getter for balance

  void addTransaction(Transaction transaction, String category) {
    transaction.category = category;
    transactions.add(transaction);
    _balance += transaction.amount;
    notifyListeners();
  }

  void updateMonthlyBudget(int month, double newBudget) {
    // Implement logic to update the monthly budget
    _monthlyBudgets[month] = newBudget;
    notifyListeners();
  }

  void addTransactions(List<Transaction> transactions) {
    this.transactions.addAll(transactions);
    _balance +=
        transactions.fold(0.0, (sum, transaction) => sum + transaction.amount);
    notifyListeners();
  }
}

// Add Transaction Form (see previous explanatio

class AddTransactionForm extends StatefulWidget {
  final Function(Transaction, String) onAddTransaction;

  const AddTransactionForm({super.key, required this.onAddTransaction});

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _selectedDate;
  final _categoryDropdownValue =
      ValueNotifier<String?>('House'); // Initial selection

  Future<void> _selectDate(BuildContext context) async {
    final initialDate = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitTransaction() {
    final description = _descriptionController.text;
    final amount = double.tryParse(_amountController.text);
    final budget = double.tryParse(_budgetController.text);

    // Handle potential errors
    if (description.isEmpty || amount == null || budget == null) {
      return; // Show an error message or handle the case as needed
    }

    final transaction = Transaction(
      id: const Uuid().v4(), // Assuming you have the uuid package installed
      date: _selectedDate ?? DateTime.now(),
      description: description,
      amount: amount,
      category: _categoryDropdownValue.value, // Use null safety
    );

    // Access TransactionProvider and update budget (assuming a method exists)
    Provider.of<TransactionProvider>(context, listen: false)
        .updateMonthlyBudget(DateTime.now().month, budget);

    Provider.of<TransactionProvider>(context, listen: false)
        .addTransaction(transaction, _categoryDropdownValue.value!);

    _descriptionController.clear();
    _amountController.clear();
    _budgetController.clear();
    _selectedDate = null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Budget'),
            ),
            Row(
              children: [
                Text(_selectedDate?.toString() ?? 'No Date Selected'),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Select Date'),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              value: _categoryDropdownValue.value,
              items: const [
                DropdownMenuItem<String>(
                  value: 'House',
                  child: Text('House'),
                ),
                DropdownMenuItem<String>(
                  value: 'Food',
                  child: Text('Food'),
                ),
                DropdownMenuItem<String>(
                  value: 'Groceries',
                  child: Text('Groceries'),
                ),
                DropdownMenuItem<String>(
                  value: 'Other',
                  child: Text('Other'),
                ),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  _categoryDropdownValue.value = newValue;
                });
              },
            ),
            ElevatedButton(
              onPressed: _submitTransaction,
              child: const Text('Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
