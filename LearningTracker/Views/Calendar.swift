import SwiftUI

// MARK: - Calendar history
struct CalendarHistory: View {
    
    let viewModel: CalendarViewModel
    
    var body: some View {
        
        //allow the user to scroll vertically through all months
        ScrollView(.vertical) {
            
            //create the month view when needed for display meaning when only scrolled to, improving performance
            LazyVStack(spacing: 28) {
                
                ForEach(viewModel.getHistoryDates(), id: \.self) { month in
                    CalendarMonthGrid(
                        month: month,
                        viewModel: viewModel
                    )
                }
            }
            
        }
        //when scrolling the app bar apears to stick to the top
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Activities")
                    .font(Fonts.ScreenTitle)
            }
        }
    }
}

// MARK: - Calendar Month Grid
struct CalendarMonthGrid : View {

    //a date with a certain month this calendar should display
    let month: Date
    let viewModel: CalendarViewModel
    private let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    var body: some View {
        VStack(spacing: 16) {

            //display the month name and year. ex: November 2026.
            Text(
                month.formatted(
                    .dateTime.month(.wide).year()
                )
            )
            .font(.headline)
            .padding(.leading , 16 )
            .frame(maxWidth: .infinity, alignment: .leading)

            //lazyVGrid arranges its children into columns, 7 flexible columns for the 7 weekdays.
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible()),
                    count: 7
                )
            ) {
                //display weekday label: SUN
                ForEach(weekdays.indices, id: \.self) { index in
                    Text(weekdays[index])
                        .font(Fonts.cardText)
                        .foregroundStyle(.gray)
                }

                //loop through every calendar cell.
                //some cells are nil (empty spaces before day 1), remaining cells contain actual dates.
                ForEach(viewModel.getMonthDates(for: month).indices, id: \.self) { index in

                    if let date = viewModel.getMonthDates(for: month)[index]{

                        // If a date exists, display its DayCell, DayCell handles the number and status colors.
                        DayCell(
                            date: date,
                            viewModel: viewModel
                        )

                    } else {
                        // Empty space to preserve weekday alignment.
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
    }
}

// MARK: - Calender Week Row
struct CalendarWeekRow: View {
    
    //No @State as it does not Own the ViewModel,it receives a reference to an existing instance, Home Owns it
    let viewModel: CalendarViewModel
    
    var body: some View {

        HStack(spacing: 10) {

            //loop to generate the cells of a week, where the viewModel provides dates of current week
            ForEach( viewModel.getCurrentWeekDates() , id: \.self) { date in

                VStack(spacing: 6) {

                    //first letter of the weekday
                    Text(date.formatted(.dateTime.weekday(.narrow)))
                        .font(Fonts.cardText)
                        .foregroundStyle(.secondary)

                    //generates style based on status logged
                    DayCell(
                        date: date,
                        viewModel: viewModel,
                        size: 44 // in row view
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - One Cell style
struct DayCell: View {
    
    let date: Date //a day
    let viewModel: CalendarViewModel
    var size: CGFloat = 38 //default in history view
    private var log: DailyLog? {viewModel.getLog(for: date)} //a log may or may not exist for a day
    private var isToday: Bool {viewModel.isToday(date)} //if cell is today style is different

    
    private var backgroundColor: Color {

        //todays cell is highlighted only if it has no log.
        if isToday && log == nil {
            return .orange
        }

        switch log?.logStatus {
            
        case .streak:
            return .orange.opacity(0.12)
        case .freeze:
            return .cyan.opacity(0.12)
        default: //Skip
            return .clear
        }
    }

    private var textColor: Color {

        //white number only for an unlogged today.
        if isToday && log == nil {
            return .white
        }

        switch log?.logStatus {
            
        case .streak:
            return .orange
        case .freeze:
            return .cyan
        default:
            return .white
        }
    }

    var body: some View {

        //the day number
        Text(date.formatted(.dateTime.day()))
            .font(Fonts.calendarNumber)
            .foregroundStyle(textColor)
            .frame(width: size, height: size)
            .background {
                Circle()
                    .fill(backgroundColor)
            }
    }
}
