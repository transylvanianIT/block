export default function Hand({ move, isAnimating }) {
    const getEmoji = () => {
        if ( move === 1) return '✊'
        if ( move === 2) return '✋'
        if ( move === 3) return '✋'
        return '❓'
    }

    return (
        <div className={`hand ${isAnimating ? 'bouncing' : ''}`}>
            <div className="hand-emoji">{getEmoji()}</div>
        </div>
    )
}