package application

// Data
type BarData struct {
	Bar       [][]interface{} `json:"bar"`
	Symbol    string          `json:"symbol"`
	Timeframe string          `json:"timeframe"`
}

type TickData struct {
	Symbol    string        `json:"symbol"`
	Timeframe string        `json:"timeframe"`
	Tick      []interface{} `json:"tick"`
}

// Events
type BarEvent struct {
	Event string  `json:"event"`
	Data  BarData `json:"data"`
}

type TickEvent struct {
	Event string   `json:"event"`
	Data  TickData `json:"data"`
}
