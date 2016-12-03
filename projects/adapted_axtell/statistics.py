class Stats:

    def __init__(self):
        self.total_firms = []
        self.average_size = []
        self.average_age = []
        self.time = 0
        self.total_time = [0]
        self.new_firms = []
        self.exit_firms = []
        self.average_output = []

    def get_time(self):
        return self.time

    def update_time(self):
        self.time += 1
        self.total_time.append(self.time)

    def get_total_firms(self):
        return self.total_firms[-1]

    def update_total_firms(self, total_firms):
        self.total_firms.append(total_firms)

    def update_average_size(self, average):
        self.average_size.append(average)

    def get_average_size(self):
        return self.average_size[-1]

    def update_average_age(self, age):
        self.average_age.append(age)

    def get_average_age(self):
        return self.average_age[-1]

    def update_new_firms(self, new_firms):
        self.new_firms.append(new_firms)

    def get_new_firms(self):
        return self.new_firms[-1]

    def update_exit_firms(self, exit_firms):
        self.exit_firms.append(exit_firms)

    def get_exit_firms(self):
        return self.exit_firms[-1]

    def update_average_output(self, output):
        self.average_output.append(output)

    def get_average_output(self):
        return self.average_output[-1]


my_stats = Stats()
